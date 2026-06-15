-- Auto-fix logic for udiffx hunk repair.
-- Used by: main.aip (#Output, #After All), auto-fix.aip (#Data)

local u_output = require("utils_output")
local CONST = require("consts")

-- Resolves the model used by auto-fix from coder params.
-- Explicit auto_fix model settings win, then auto_context model fallbacks, then the coder model.
local function resolve_auto_fix_model(coder_params)
	if type(coder_params) ~= "table" then
		return nil
	end

	local auto_fix = coder_params.auto_fix
	if auto_fix == false then
		return nil
	end
	if type(auto_fix) == "string" and auto_fix ~= "" then
		return auto_fix
	end
	if type(auto_fix) == "table" then
		if auto_fix.enabled == false then
			return nil
		end
		if type(auto_fix.model) == "string" and auto_fix.model ~= "" then
			return auto_fix.model
		end
	end

	local auto_context = coder_params.auto_context
	if type(auto_context) == "string" and auto_context ~= "" then
		return auto_context
	end
	if type(auto_context) == "table" and auto_context.enabled ~= false then
		if type(auto_context.code_map_model) == "string" and auto_context.code_map_model ~= "" then
			return auto_context.code_map_model
		end
		if type(auto_context.model) == "string" and auto_context.model ~= "" then
			return auto_context.model
		end
	end

	if type(coder_params.model) == "string" and coder_params.model ~= "" then
		return coder_params.model
	end

	return nil
end

-- Gets the ordered list of models used by the tiered auto-fix retry strategy.
-- Returns a table of up to three model strings (may be nil if not configured):
--   [1] code_map_model, [2] auto_context.model, [3] coder model.
-- Used by: run_auto_fix_loop
local function get_auto_fix_models(coder_params)
	local models = {}

	local code_map_model = nil
	if not is_null(coder_params) and type(coder_params.auto_context) == "table" then
		code_map_model = coder_params.auto_context.code_map_model
	end
	table.insert(models, code_map_model)

	local ac_model = nil
	if not is_null(coder_params) and type(coder_params.auto_context) == "table" then
		ac_model = coder_params.auto_context.model
	end
	table.insert(models, ac_model)

	local coder_model = nil
	if type(coder_params) == "table" and type(coder_params.model) == "string" then
		coder_model = coder_params.model
	end
	table.insert(models, coder_model)

	return models
end

-- Resolves the auto_fix configuration by normalizing different types.
local function resolve_auto_fix_config(cfg, env)
	local resolved = {
		enabled = false,
		model = nil,
		max_retries = 6
	}

	if type(cfg) == "boolean" then
		resolved.enabled = cfg
	elseif type(cfg) == "string" then
		resolved.enabled = true
		resolved.model = cfg
	elseif type(cfg) == "table" then
		resolved.enabled = cfg.enabled ~= false
		resolved.model = cfg.model
		resolved.max_retries = tonumber(cfg.max_retries) or 6
		for k, v in pairs(cfg) do
			if k ~= "enabled" and k ~= "model" and k ~= "max_retries" then
				resolved[k] = v
			end
		end
	end

	if resolved.enabled == true and (is_null(resolved.model) or resolved.model == "") then
		local model_params = nil
		if type(env) == "table" then
			model_params = env.coder_params or env
		end
		resolved.model = resolve_auto_fix_model(model_params)
	end

	if resolved.base_eligible == nil then
		if type(env) == "table" then
			local has_cache = false
			if type(env.coder_workbench) == "table" and not is_null(env.coder_workbench.cache_dir) and env.coder_workbench.cache_dir ~= "" then
				has_cache = true
			end
			resolved.base_eligible = resolved.enabled == true
					and env.write_mode == true
					and type(env.file_content_mode) == "table"
					and env.file_content_mode.udiffx == true
					and has_cache
		else
			resolved.base_eligible = resolved.enabled
		end
	end

	return resolved
end

-- Loads the text content of a file at the given path.
-- Returns the content string, or nil if the file does not exist or is not readable.
-- Used by: auto-fix.aip (#Data)
local function load_text_file(path)
	if is_null(path) or path == "" or not aip.file.exists(path) then
		return nil
	end
	local file = aip.file.load(path)
	if type(file) ~= "table" or type(file.content) ~= "string" then
		return nil
	end
	return file.content
end

-- Normalizes a file path relative to base_dir for failure reporting.
-- Used by: build_failed_changes_from_status, collect_successful_changes_from_status
local function normalize_failed_change_path(base_dir, file_path)
	if type(file_path) ~= "string" or file_path == "" then
		return ""
	end
	if file_path:sub(1, 1) == "/" or file_path:match("^%a:[/\\]") then
		return file_path
	end
	if is_null(base_dir) or base_dir == "" then
		return file_path
	end
	return aip.path.join(base_dir, file_path)
end

-- Checks whether structured failed hunk details are available.
-- Used by: should_defer_failed_changes
local function failed_hunk_details_available(files_changes_failed, file_changes_status)
	if type(files_changes_failed) == "table" then
		for _, item in ipairs(files_changes_failed) do
			if type(item) == "table" and type(item.error_hunks) == "table" and #item.error_hunks > 0 then
				return true
			end
		end
	end

	if type(file_changes_status) == "table" and type(file_changes_status.items) == "table" then
		for _, item in ipairs(file_changes_status.items) do
			if type(item) == "table" and item.success == false
					and type(item.error_hunks) == "table" and #item.error_hunks > 0 then
				return true
			end
		end
	end

	return false
end

-- Adds a changed file entry uniquely by path.
-- Used by: collect_successful_changes_from_status, run_auto_fix_loop
local function add_changed_file_unique(files_changed, seen_paths, item)
	local path = nil
	local status = nil
	local kind = nil

	if type(item) == "table" then
		path = item.path or item.file_path
		status = item.status or u_output.file_change_status_letter(item.kind)
		kind = item.kind
	else
		path = tostring(item)
	end

	if is_null(path) or path == "" then
		return
	end
	if is_null(status) or status == "" then
		status = "M"
	end

	local key = tostring(path)
	if seen_paths[key] then
		return
	end

	seen_paths[key] = true
	table.insert(files_changed, {
		path = path,
		status = status,
		kind = kind
	})
end

-- Collects successful file changes from an apply status.
-- Used by: run_auto_fix_loop
local function collect_successful_changes_from_status(file_changes_status, base_dir)
	local files_changed = {}
	local seen_paths = {}

	if type(file_changes_status) ~= "table" or type(file_changes_status.items) ~= "table" then
		return files_changed, seen_paths
	end

	for _, item in ipairs(file_changes_status.items) do
		if type(item) == "table" and item.success == true then
			add_changed_file_unique(files_changed, seen_paths, {
				path = normalize_failed_change_path(base_dir, item.file_path or item.path),
				status = u_output.file_change_status_letter(item.kind),
				kind = item.kind
			})
		end
	end

	return files_changed, seen_paths
end

-- Builds a synthetic file_changes_status from the aggregated auto-fix results.
-- Used by: run_auto_fix_loop
local function build_auto_fix_file_changes_status(files_changed, files_changes_failed)
	local items = {}

	if type(files_changed) == "table" then
		for _, item in ipairs(files_changed) do
			if type(item) == "table" and not is_null(item.path) and item.path ~= "" then
				table.insert(items, {
					file_path = item.path,
					kind = item.kind or "Patch",
					success = true
				})
			end
		end
	end

	local fail_count = 0
	if type(files_changes_failed) == "table" then
		for _, item in ipairs(files_changes_failed) do
			if type(item) == "table" and not is_null(item.path) and item.path ~= "" then
				fail_count = fail_count + 1
				table.insert(items, {
					file_path = item.path,
					kind = item.kind or "Patch",
					success = false,
					error_msg = item.error_msg,
					error_hunks = item.error_hunks
				})
			end
		end
	end

	return {
		success = fail_count == 0,
		total_count = #items,
		success_count = #items - fail_count,
		fail_count = fail_count,
		items = items
	}
end

-- Builds a human-readable completion response for the auto-fix result.
-- Used by: main.aip (#After All)
function build_auto_fix_completion_response(files_changed, files_changes_failed, auto_fix_result, data)
	files_changed = type(files_changed) == "table" and files_changed or {}
	files_changes_failed = type(files_changes_failed) == "table" and files_changes_failed or {}

	if #files_changed == 0 and #files_changes_failed == 0 then
		return nil
	end

	local response = nil
	if #files_changes_failed == 0 then
		response = "✅ "
	else
		response = "⚠ "
	end

	if #files_changed == 0 then
		response = response .. "No File changed."
	else
		local change_report = u_output.build_changed_files_report(files_changed)
		if change_report and not is_null(change_report) then
			response = response .. change_report.header .. "\n"
			response = response .. table.concat(change_report.lines, "\n")
		end
	end

	if #files_changes_failed > 0 then
		local tui_block = u_output.format_failed_changes_for_tui(files_changes_failed)
		if tui_block ~= nil and tui_block ~= "" then
			response = response .. "\n\nSome changes still failed to apply:\n" .. tui_block
		end
	end

	local summary_line = build_auto_fix_summary_line(auto_fix_result)
	if summary_line ~= nil then
		response = response .. "\n\n" .. summary_line
		if #files_changes_failed > 0 then
			local remaining_lines = {}
			local remaining_file_count = 0
			for _, fc in ipairs(files_changes_failed) do
				if type(fc) == "table" and not is_null(fc.path) and fc.path ~= "" then
					local failed_count = u_output.failed_hunk_counts(fc)
					remaining_file_count = remaining_file_count + 1
					local hunk_txt = failed_count == 1 and "1 failed hunk" or (tostring(failed_count) .. " failed hunks")
					table.insert(remaining_lines, "→ " .. fc.path .. " (" .. hunk_txt .. ")")
				end
			end
			if #remaining_lines > 0 then
				response = response .. "\n\n❗ Still fail - fixing " .. remaining_file_count .. " files\n"
				response = response .. table.concat(remaining_lines, "\n")
			end
		end
	end

	if type(data) == "table" and data.prompt_file_rel_path then
		response = response .. "\n\nCheck prompt file for more AI answer. Prompt file:"
		response = response .. "\n→ " .. data.prompt_file_rel_path
	end

	return response
end

-- Builds the in-progress consolidated `completed_run` content for an auto-fix attempt (State 2).
-- Renders the changed-files report with a `▶▶` prefix instead of `✅`, then appends a
-- `❗ auto-fix N - fixing F files` section listing each current failing file with its hunk count.
-- Used by: run_auto_fix_loop
function build_inprogress_coding_content(files_changed, attempt_num, current_failed_changes)
	files_changed = type(files_changed) == "table" and files_changed or {}
	current_failed_changes = type(current_failed_changes) == "table" and current_failed_changes or {}

	local response = "▶▶ "
	if #files_changed == 0 then
		response = response .. "No File changed."
	else
		local change_report = u_output.build_changed_files_report(files_changed)
		if change_report and not is_null(change_report) then
			response = response .. change_report.header .. "\n"
			response = response .. table.concat(change_report.lines, "\n")
		end
	end

	if #current_failed_changes > 0 then
		local lines = {}
		local file_count = 0
		for _, fc in ipairs(current_failed_changes) do
			if type(fc) == "table" and not is_null(fc.path) and fc.path ~= "" then
				local failed_count = u_output.failed_hunk_counts(fc)
				file_count = file_count + 1
				local hunk_txt = failed_count == 1 and "1 failed hunk" or (tostring(failed_count) .. " failed hunks")
				table.insert(lines, "→ " .. fc.path .. " (" .. hunk_txt .. ")")
			end
		end
		if #lines > 0 then
			response = response .. "\n\n❗ auto-fix " .. tostring(attempt_num) .. " - fixing " .. file_count .. " files\n"
			response = response .. table.concat(lines, "\n")
		end
	end

	return response
end

-- Builds a simple success summary line. Returns `(✅ auto-fix successful)` when any
-- auto-fix attempt produced a fix, or nil otherwise.
-- Used by: build_auto_fix_completion_response
function build_auto_fix_summary_line(auto_fix_result)
	if type(auto_fix_result) ~= "table" then
		return nil
	end

	local attempts_with_fixes = tonumber(auto_fix_result.auto_fix_attempts_with_fixes) or 0
	if attempts_with_fixes == 0 then
		return nil
	end

	return "(✅ auto-fix successful)"
end

-- Determines whether to defer immediate failure reporting so auto-fix can run first.
-- Used by: main.aip (#Output)
function should_defer_failed_changes(files_changes_failed, data, file_changes_status)
	if type(files_changes_failed) ~= "table" or #files_changes_failed == 0 then
		return false
	end
	if type(data) ~= "table" then
		return false
	end
	if data.write_mode ~= true then
		return false
	end
	if type(data.file_content_mode) ~= "table" or data.file_content_mode.udiffx ~= true then
		return false
	end
	if type(data.auto_fix) ~= "table" or data.auto_fix.eligible ~= true then
		return false
	end
	if type(file_changes_status) ~= "table" or tonumber(file_changes_status.fail_count or 0) == 0 then
		return false
	end
	if not failed_hunk_details_available(files_changes_failed, file_changes_status) then
		return false
	end

	return true
end

-- Builds a failed-changes list from a file_changes_status object.
-- Used by: main.aip (#After All)
function build_failed_changes_from_status(file_changes_status, base_dir)
	if type(file_changes_status) ~= "table" or type(file_changes_status.items) ~= "table" then
		return {}
	end

	local files_changes_failed = {}
	for _, item in ipairs(file_changes_status.items) do
		if type(item) == "table" and item.success == false then
			local reason = item.error_msg or "Unknown error"
			local failed_count = 0
			if type(item.error_hunks) == "table" then
				failed_count = #item.error_hunks
			end
			table.insert(files_changes_failed, {
				path = normalize_failed_change_path(base_dir, item.file_path or item.path),
				error_msg = reason,
				error_hunks = item.error_hunks,
				total_count = u_output.resolve_failed_hunk_total_count(item, failed_count),
				kind = item.kind,
				changes_info = {
					failed_changes = { { reason = reason, search = "UDIFFX Block failed: " .. reason } }
				}
			})
		end
	end

	return files_changes_failed
end

-- Resolves the auto-fix diagnostics directory from the workbench cache dir.
-- Used by: write_auto_fix_diagnostics, run_auto_fix_loop
local function resolve_auto_fix_dir(coder_workbench)
	if type(coder_workbench) ~= "table" then
		return nil
	end
	local cache_dir = coder_workbench.cache_dir
	if is_null(cache_dir) or cache_dir == "" then
		return nil
	end
	return tostring(cache_dir):gsub("/+$", "") .. "/auto-fix"
end

-- Builds structured JSON info for the latest auto-fix failure.
-- Used by: write_auto_fix_diagnostics
local function build_auto_fix_info(files_changes_failed)
	local failed_paths = {}
	local failed_files = {}
	for _, fc in ipairs(files_changes_failed) do
		if type(fc) == "table" and not is_null(fc.path) and fc.path ~= "" then
			table.insert(failed_paths, fc.path)
			local failed_count = u_output.failed_hunk_counts(fc)
			table.insert(failed_files, {
				file_path = fc.path,
				failed_hunks_count = failed_count
			})
		end
	end

	return {
		failed_paths = failed_paths,
		failed_files = failed_files
	}
end

-- Writes the latest auto-fix diagnostics (markdown report and JSON info) under the
-- workbench cache auto-fix directory. Both files are overwritten on each call so only
-- the latest failure state is retained.
-- Used by: main.aip (#After All), run_auto_fix_loop
function write_auto_fix_diagnostics(files_changes_failed, coder_workbench)
	if type(files_changes_failed) ~= "table" or #files_changes_failed == 0 then
		return nil, "no failed changes"
	end

	local auto_fix_dir = resolve_auto_fix_dir(coder_workbench)
	if is_null(auto_fix_dir) or auto_fix_dir == "" then
		return nil, "missing workbench cache dir"
	end

	local ensure_res = aip.file.ensure_dir(auto_fix_dir)
	if type(ensure_res) == "table" and ensure_res.error then
		return nil, ensure_res.error
	end

	local report_path = auto_fix_dir .. "/last_udiffx_fail_reports.md"
	local info_path = auto_fix_dir .. "/last_udiffx_fail_info.json"

	local report_content = u_output.format_failed_changes_for_file_report(files_changes_failed) or ""
	local info = build_auto_fix_info(files_changes_failed)
	local info_content = aip.json.stringify_pretty(info)

	local save_report_res = aip.file.save(report_path, report_content)
	if type(save_report_res) == "table" and save_report_res.error then
		return nil, save_report_res.error
	end

	local save_info_res = aip.file.save(info_path, info_content)
	if type(save_info_res) == "table" and save_info_res.error then
		return nil, save_info_res.error
	end

	return {
		dir = auto_fix_dir,
		report_path = report_path,
		info_path = info_path
	}
end

-- Resolves the failed changes list for a deferred coder response.
-- Prefers the explicit failed-change list, then reconstructs from file_changes_status when needed.
-- Used by: run_auto_fix_loop
local function resolve_deferred_failed_changes(coder_response, base_dir)
	if type(coder_response) ~= "table" then
		return {}
	end

	local failed_changes = coder_response.files_changes_failed
	if type(failed_changes) == "table" and #failed_changes > 0 then
		return failed_changes
	end

	if type(coder_response.file_changes_status) == "table" then
		return build_failed_changes_from_status(coder_response.file_changes_status, base_dir)
	end

	return {}
end

-- Totals the failed hunk count across a list of failed change items.
-- Used by: run_auto_fix_loop
local function count_failed_hunks(files_changes_failed)
	local total = 0
	if type(files_changes_failed) ~= "table" then
		return total
	end
	for _, fc in ipairs(files_changes_failed) do
		local failed_count = u_output.failed_hunk_counts(fc)
		if type(failed_count) == "number" then
			total = total + failed_count
		end
	end
	return total
end

local function update_auto_fix_completion_pin(auto_fix_result)
	if type(auto_fix_result) ~= "table" then
		return
	end

	local remaining = auto_fix_result.remaining_failed_changes
	local files_changed = auto_fix_result.files_changed

	local content = build_auto_fix_pin_content(files_changed, remaining)

	if content then
		aip.run.pin("auto_fix_files", 2, { label = "Auto-Fix:", content = content })
	end
end

-- Orchestrates the bounded auto-fix retry loop for a single deferred coder response.
-- It runs the built-in pro@coder/auto-fix agent, applies each returned response through
-- the existing apply path, and rewrites diagnostics after each attempt that still has failures.
-- Used by: main.aip (#After All)
function run_auto_fix_loop(coder_response, report_data, coder_workbench, options)
	options = options or {}
	local max_retries = 3
	if type(report_data) == "table" and type(report_data.auto_fix) == "table" and report_data.auto_fix.max_retries then
		max_retries = report_data.auto_fix.max_retries
	else
		max_retries = options.max_retries or 3
	end

	if type(coder_response) ~= "table" then
		return {}, report_data, nil
	end

	local base_dir = type(report_data) == "table" and report_data.base_dir or nil
	local failed_changes = resolve_deferred_failed_changes(coder_response, base_dir)
	if type(failed_changes) ~= "table" or #failed_changes == 0 then
		delete_auto_fix_diagnostics(coder_workbench)
		return {}, report_data, nil
	end

	local coder_prompt_dir = type(report_data) == "table" and report_data.coder_prompt_dir or nil
	local apply_data = report_data
	if type(apply_data) ~= "table" then
		apply_data = {
			base_dir = base_dir,
			write_mode = true,
			file_content_mode = { udiffx = true }
		}
	end

	local all_files_changed, seen_changed_paths = collect_successful_changes_from_status(
		coder_response.file_changes_status, base_dir)
	local auto_fix_result = {
		files_changed = all_files_changed,
		file_changes_status = build_auto_fix_file_changes_status(all_files_changed, failed_changes),
		remaining_failed_changes = failed_changes,
		attempts = 0,
		auto_fix_attempts_with_fixes = 0,
		auto_fix_files_fixed = 0,
		auto_fix_hunks_fixed = 0
	}
	-- Build models_to_use array of length max_retries for tiered model distribution.
	local models_to_use = {}
	do
		local raw_auto_fix = nil
		if type(report_data) == "table" and type(report_data.coder_params) == "table" then
			raw_auto_fix = report_data.coder_params.auto_fix
		end
		local explicit_auto_fix_model = nil
		if type(raw_auto_fix) == "string" and raw_auto_fix ~= "" then
			explicit_auto_fix_model = raw_auto_fix
		elseif type(raw_auto_fix) == "table" and type(raw_auto_fix.model) == "string" and raw_auto_fix.model ~= "" then
			explicit_auto_fix_model = raw_auto_fix.model
		end

		if explicit_auto_fix_model then
			for _ = 1, max_retries do
				table.insert(models_to_use, explicit_auto_fix_model)
			end
		else
			-- Tiered strategy: ordered list of up to three models.
			local coder_params = nil
			if type(report_data) == "table" then
				coder_params = report_data.coder_params
			end
			---@cast coder_params any

			local tier_models = get_auto_fix_models(coder_params)
			local coder_model = nil

			if not is_null(coder_params) and type(coder_params.model) == "string" then
				coder_model = coder_params.model
			end

			for i, m in ipairs(tier_models) do
				if is_null(m) or m == "" then
					tier_models[i] = coder_model
				end
			end

			local n_models = #tier_models
			local quota = max_retries
			local per_model = {}
			for i = 1, n_models do
				local remaining_models = n_models - i + 1
				local count = math.ceil(quota / remaining_models)
				per_model[i] = count
				quota = quota - count
			end

			for i = 1, n_models do
				local count = per_model[i]
				local model = tier_models[i]
				for _ = 1, count do
					table.insert(models_to_use, model)
				end
			end
		end
	end

	for _attempt = 1, max_retries do
		auto_fix_result.attempts = _attempt

		-- Update the consolidated main pin with the State 2 in-progress content for this attempt.
		aip.run.pin("completed_run", 0, {
			label = CONST.LABEL_COMPLETED_AUTO_FIX,
			content = build_inprogress_coding_content(auto_fix_result.files_changed, _attempt, failed_changes)
		})

		-- Capture the pre-attempt failed hunk count and unique fixed-file baseline to derive this attempt's gains.
		local pre_attempt_failed_hunks = count_failed_hunks(failed_changes)
		local pre_attempt_fixed_files = #auto_fix_result.files_changed

		-- Write the latest diagnostics for the current failed state before each auto-fix attempt.
		local _diag_res, _diag_err = write_auto_fix_diagnostics(failed_changes, coder_workbench)

		local auto_fix_dir = resolve_auto_fix_dir(coder_workbench)

		local run_res = aip.agent.run("auto-fix", {
			input = {
				auto_fix_dir = auto_fix_dir,
				base_dir = base_dir,
				coder_workbench = coder_workbench
			},
			options = (not is_null(models_to_use[_attempt]) and models_to_use[_attempt] ~= "" and { model = models_to_use[_attempt] }) or
					nil,
			agent_base_dir = CTX.AGENT_FILE_DIR
		})

		-- The auto-fix sub-agent applies its corrected changes in its own # Output stage and returns
		-- the structured apply result. Consume that result here instead of re-applying the content.
		local sub_output = nil
		if type(run_res) == "table" and type(run_res.outputs) == "table" and #run_res.outputs > 0 then
			local first = run_res.outputs[1]
			if type(first) == "table" then
				sub_output = first
			end
		end

		local auto_fix_content = nil
		local attempt_files_changed = nil
		local attempt_failed_changes = nil
		if type(sub_output) == "table" then
			auto_fix_content = sub_output.auto_fix_content
			attempt_files_changed = sub_output.files_changed
			attempt_failed_changes = sub_output.files_changes_failed
		end

		-- A nil run, a skip, or missing content means we cannot proceed; fall back to current failures.
		if type(auto_fix_content) ~= "string" or aip.text.trim(auto_fix_content) == "" then
			auto_fix_result.remaining_failed_changes = failed_changes
			auto_fix_result.file_changes_status = build_auto_fix_file_changes_status(auto_fix_result.files_changed,
				failed_changes)
			update_auto_fix_completion_pin(auto_fix_result)
			return failed_changes, apply_data, auto_fix_result
		end

		if type(attempt_files_changed) == "table" then
			for _, item in ipairs(attempt_files_changed) do
				add_changed_file_unique(auto_fix_result.files_changed, seen_changed_paths, item)
			end
		end

		-- Track aggregate counters for this attempt: newly fixed files (unique) and fixed hunks.
		local attempt_remaining_failed = type(attempt_failed_changes) == "table" and attempt_failed_changes or {}
		local post_attempt_failed_hunks = count_failed_hunks(attempt_remaining_failed)
		local newly_fixed_files = #auto_fix_result.files_changed - pre_attempt_fixed_files
		local newly_fixed_hunks = pre_attempt_failed_hunks - post_attempt_failed_hunks
		if newly_fixed_hunks < 0 then
			newly_fixed_hunks = 0
		end
		if newly_fixed_files > 0 or newly_fixed_hunks > 0 then
			auto_fix_result.auto_fix_attempts_with_fixes = auto_fix_result.auto_fix_attempts_with_fixes + 1
			auto_fix_result.auto_fix_files_fixed = auto_fix_result.auto_fix_files_fixed + newly_fixed_files
			auto_fix_result.auto_fix_hunks_fixed = auto_fix_result.auto_fix_hunks_fixed + newly_fixed_hunks
		end

		if type(attempt_failed_changes) ~= "table" or #attempt_failed_changes == 0 then
			-- Fully repaired; no remaining failures.
			delete_auto_fix_diagnostics(coder_workbench)
			auto_fix_result.remaining_failed_changes = {}
			auto_fix_result.file_changes_status = build_auto_fix_file_changes_status(auto_fix_result.files_changed, {})
			update_auto_fix_completion_pin(auto_fix_result)
			return {}, apply_data, auto_fix_result
		end

		failed_changes = attempt_failed_changes
		auto_fix_result.remaining_failed_changes = failed_changes
		auto_fix_result.file_changes_status = build_auto_fix_file_changes_status(auto_fix_result.files_changed,
			failed_changes)
	end

	update_auto_fix_completion_pin(auto_fix_result)
	return failed_changes, apply_data, auto_fix_result
end

-- Resolves the auto-fix directory from an input table (for use by auto-fix.aip #Data).
-- Used by: auto-fix.aip (#Data)
function get_auto_fix_dir_from_input(value)
	if type(value) ~= "table" then
		return nil
	end

	local dir = value.auto_fix_dir
	if not is_null(dir) and dir ~= "" then
		return tostring(dir):gsub("/+$", "")
	end

	return nil
end

-- Resolves the apply base_dir from an input table (for use by auto-fix.aip #Data).
-- Used by: auto-fix.aip (#Data)
function get_apply_base_dir_from_input(value)
	if type(value) ~= "table" then
		return nil
	end
	local base_dir = value.base_dir
	if not is_null(base_dir) and base_dir ~= "" then
		return base_dir
	end
	return nil
end

-- Builds the auto-fix completion pin content from applied/failed change lists.
-- Returns "✅ Fixed n file(s):..." when there are no remaining failures, or
-- "❗ Still have n errors..." when failures remain. Returns nil when there is nothing to report.
-- Used by: auto-fix.aip (#Output), update_auto_fix_completion_pin
function build_auto_fix_pin_content(files_changed, files_changes_failed)
	files_changed = type(files_changed) == "table" and files_changed or {}
	files_changes_failed = type(files_changes_failed) == "table" and files_changes_failed or {}

	local has_remaining = #files_changes_failed > 0

	if has_remaining then
		local lines = {}
		local total_error_files = 0
		for _, fc in ipairs(files_changes_failed) do
			if type(fc) == "table" and not is_null(fc.path) and fc.path ~= "" then
				local failed_count = u_output.failed_hunk_counts(fc)
				total_error_files = total_error_files + 1
				local hunk_txt = failed_count == 1 and "1 fail hunk" or (tostring(failed_count) .. " fail hunks")
				table.insert(lines, "- " .. fc.path .. " (" .. hunk_txt .. ")")
			end
		end
		if #lines > 0 then
			return "❗ Still have " .. total_error_files .. " errors\n" .. table.concat(lines, "\n")
		end
		return nil
	end

	if #files_changed > 0 then
		local lines = {}
		for _, item in ipairs(files_changed) do
			local path = type(item) == "table" and item.path or item
			if not is_null(path) and path ~= "" then
				table.insert(lines, "- " .. tostring(path))
			end
		end
		if #lines > 0 then
			return "✅ Fixed " .. #lines .. " file(s):\n" .. table.concat(lines, "\n")
		end
	end

	return nil
end

-- Deletes the auto-fix diagnostic files (report and info) from the workbench cache directory.
-- Used by: run_auto_fix_loop
function delete_auto_fix_diagnostics(coder_workbench)
	local auto_fix_dir = resolve_auto_fix_dir(coder_workbench)
	if is_null(auto_fix_dir) or auto_fix_dir == "" then
		return
	end
	aip.file.delete(auto_fix_dir)
end

return {
	resolve_auto_fix_config = resolve_auto_fix_config,
	resolve_auto_fix_model = resolve_auto_fix_model,
	get_auto_fix_models = get_auto_fix_models,
	load_text_file = load_text_file,
	normalize_failed_change_path = normalize_failed_change_path,
	failed_hunk_details_available = failed_hunk_details_available,
	add_changed_file_unique = add_changed_file_unique,
	collect_successful_changes_from_status = collect_successful_changes_from_status,
	build_auto_fix_file_changes_status = build_auto_fix_file_changes_status,
	build_auto_fix_completion_response = build_auto_fix_completion_response,
	build_inprogress_coding_content = build_inprogress_coding_content,
	build_auto_fix_summary_line = build_auto_fix_summary_line,
	should_defer_failed_changes = should_defer_failed_changes,
	build_failed_changes_from_status = build_failed_changes_from_status,
	build_auto_fix_info = build_auto_fix_info,
	write_auto_fix_diagnostics = write_auto_fix_diagnostics,
	resolve_auto_fix_dir = resolve_auto_fix_dir,
	resolve_deferred_failed_changes = resolve_deferred_failed_changes,
	run_auto_fix_loop = run_auto_fix_loop,
	get_auto_fix_dir_from_input = get_auto_fix_dir_from_input,
	get_apply_base_dir_from_input = get_apply_base_dir_from_input,
	build_auto_fix_pin_content = build_auto_fix_pin_content,
	delete_auto_fix_diagnostics = delete_auto_fix_diagnostics,
}
