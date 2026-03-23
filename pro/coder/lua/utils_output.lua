-- CONST
local CONST = require("consts")

function build_info_lines(ai_response, data)
	local first_line = ">   Info: " .. ai_response.info
	local second_line = ""
	-- Now, see if we can split the `| Model` ina second line.
	local model_index = string.find(first_line, "| Model")
	if model_index then
		-- Extract the substring starting from the '| Model'
		second_line = "\n>  " .. string.sub(first_line, model_index + 2) -- "+ 2" to skip the "| "
		first_line = string.sub(first_line, 1, model_index - 1)
	end

	local content             = first_line .. second_line
	local knowledge_files_num = data.knowledge_files and #data.knowledge_files or 0
	local context_files_num   = data.context_files and #data.context_files or 0
	local working_files_num   = data.working_files and #data.working_files or 0
	content                   = content .. "\n>  Files: Context Files: " .. context_files_num .. " | "
			.. "Working Files: " .. working_files_num .. " | " .. "Knowledge Files: " .. knowledge_files_num

	if data.write_mode then
		content = content ..
				"\n>   Note: write_mode is true, so content below this line will **NOT** be included in next run/prompt."
	else
		content = content ..
				"\n>   Note: write_mode is false, so content below this line **WILL** be included in next run/prompt."
	end
	return content
end

function process_ui_directives(content)
	-- if API not here, then do nothing
	if aip.tag == nil or aip.tag.extract == nil
			or aip.task == nil or aip.task.pin == nil
			or aip.text == nil or aip.text.trim == nil then
		return
	end

	local elems = aip.tag.extract(content, { "suggested_git_command", "AIP_TO_PIN", "missing_files" }) or {}
	if type(elems) ~= "table" then return end

	for _, elem in ipairs(elems) do
		if elem.tag == "suggested_git_command" then
			-- process git commit suggestion
			aip.task.pin("gitc", 1, {
				label   = CONST.LABEL_GIT_COMMIT,
				content = aip.text.trim(elem.content)
			})
		elseif elem.tag == "AIP_TO_PIN" then
			local body = aip.text.trim(elem.content)
			if body ~= nil and body ~= "" then
				local label = elem.attrs and elem.attrs.label or nil
				local priority = tonumber(elem.attrs and elem.attrs.priority or nil)
				if priority == nil or priority % 1 ~= 0 then
					priority = 1
				end
				aip.task.pin(label, priority, {
					label   = label,
					content = body
				})
			end
		elseif elem.tag == "missing_files" then
			local info = aip.tag.extract_as_map(elem.content, { "mf_message", "mf_files" })
			if info.mf_message and info.mf_files then
				local mf_msg = aip.text.trim(info.mf_message.content)
				aip.task.pin("mf_msg", 0, {
					label   = "Missing Info:",
					content = mf_msg
				})
				local mf_files = info.mf_files.content:gsub("^\n", "") -- remove first empty line
				aip.task.pin("mf_files", 0, {
					label   = "Missing Files:",
					content = mf_files
				})
			end
		end
	end
end

local function build_failed_hunk_report_block(fc)
	if type(fc) ~= "table" then
		return nil
	end

	local error_hunks = fc.error_hunks
	if type(error_hunks) ~= "table" or #error_hunks == 0 then
		return nil
	end

	local lines = {
		"----",
		"- " .. tostring(fc.path or "")
	}

	local failed_count = #error_hunks
	local total_count = tonumber(fc.total_count or nil)
	local success_count = tonumber(fc.success_count or nil)
	local summary = tostring(failed_count) .. " hunks failed to applied"
	if total_count ~= nil and success_count ~= nil and success_count > 0 then
		summary = summary .. " (" .. tostring(success_count) .. " other hunk got applied)"
	elseif total_count ~= nil then
		local other_applied = total_count - failed_count
		if other_applied > 0 then
			summary = summary .. " (" .. tostring(other_applied) .. " other hunk got applied)"
		end
	end
	table.insert(lines, summary)

	for idx, error_hunk in ipairs(error_hunks) do
		table.insert(lines, "")
		table.insert(lines, "Fail hunk " .. idx .. ":")
		if error_hunk.cause and error_hunk.cause ~= "" then
			table.insert(lines, "Cause: " .. error_hunk.cause)
		end
		table.insert(lines, "```text")
		table.insert(lines, error_hunk.hunk_body or "")
		table.insert(lines, "```")
	end

	table.insert(lines, "----")
	return table.concat(lines, "\n")
end

local function file_change_status_letter(kind)
	if kind == "New" then return "A" end
	if kind == "Patch" then return "M" end
	if kind == "Append" then return "M" end
	if kind == "Delete" then return "D" end
	if kind == "Rename" then return "R" end
	if kind == "Copy" then return "C" end
	return nil
end

local function file_change_status_rank(status)
	if status == "A" then return 1 end
	if status == "M" then return 2 end
	if status == "R" then return 3 end
	if status == "C" then return 4 end
	if status == "D" then return 5 end
	return 99
end

local function sort_changed_files(files_changed)
	table.sort(files_changed, function(a, b)
		local a_status = type(a) == "table" and a.status or nil
		local b_status = type(b) == "table" and b.status or nil
		local a_path = type(a) == "table" and a.path or tostring(a)
		local b_path = type(b) == "table" and b.path or tostring(b)

		local a_rank = file_change_status_rank(a_status)
		local b_rank = file_change_status_rank(b_status)
		if a_rank ~= b_rank then
			return a_rank < b_rank
		end
		return a_path < b_path
	end)
end

function build_changed_files_report(files_changed)
	if not files_changed or #files_changed == 0 then
		return nil
	end

	local has_structured_status = true
	for _, item in ipairs(files_changed) do
		if type(item) ~= "table" or not item.path or not item.status then
			has_structured_status = false
			break
		end
	end

	if not has_structured_status then
		local paths = {}
		for _, item in ipairs(files_changed) do
			if type(item) == "table" and item.path then
				table.insert(paths, item.path)
			else
				table.insert(paths, tostring(item))
			end
		end

		local file_txt = "file"
		if #paths > 1 then
			file_txt = "files"
		end

		return {
			header = "" .. #paths .. " " .. file_txt .. " changed:",
			lines = { "→ " .. table.concat(paths, "\n→ ") }
		}
	end

	local items = {}
	for _, item in ipairs(files_changed) do
		table.insert(items, {
			path = item.path,
			status = item.status
		})
	end
	sort_changed_files(items)

	local file_txt = "file"
	if #items > 1 then
		file_txt = "files"
	end

	local lines = {}
	for _, item in ipairs(items) do
		table.insert(lines, item.status .. " → " .. item.path)
	end

	return {
		header = "" .. #items .. " " .. file_txt .. " changed (A: added, M: modified, R: renamed, C: copied, D: deleted):\n",
		lines = lines
	}
end

-- ==== RETURN

-- Applies file changes based on the mode defined in data (udiffx or AIP_FILE_CHANGE tags).
-- Returns the processed content (without the change directives), a list of changed files,
-- and a list of failed change info.
function apply_changes(ai_content, data)
	local base_dir = data.base_dir
	local files_changed = {}
	local files_changes_failed = {}
	local second_part = ai_content

	if data.write_mode ~= true then
		return second_part, files_changed, files_changes_failed
	end

	if data.file_content_mode.udiffx then
		local changes_status, other_content = aip.udiffx.apply_file_changes(ai_content, base_dir, { extrude = "content" })
		second_part = other_content
		if changes_status.items then
			for _, item in ipairs(changes_status.items) do
				local f_path = aip.path.join(base_dir, item.file_path)
				if item.success then
					local status = file_change_status_letter(item.kind)
					if status then
						table.insert(files_changed, {
							path = f_path,
							status = status,
							kind = item.kind
						})
					else
						table.insert(files_changed, f_path)
					end
				else
					local reason = item.error_msg or "Unknown error"
					table.insert(files_changes_failed, {
						path = f_path,
						error_hunks = item.error_hunks,
						total_count = changes_status.total_count,
						success_count = changes_status.success_count,
						changes_info = {
							failed_changes = { { reason = reason, search = "UDIFFX Block failed: " .. reason } }
						}
					})
				end
			end
		elseif changes_status.error then
			print("Error applying udiffx: " .. changes_status.error)
		end
	else
		local elems, other_content = aip.tag.extract(ai_content, { "AIP_FILE_CHANGE" }, { extrude = "content" })
		second_part = other_content
		for _, elem in ipairs(elems) do
			local file_path = elem.attrs and elem.attrs.file_path

			local file_change_content = aip.md.outer_block_content_or_raw(aip.text.trim(elem.content))
			if file_path then
				file_path = aip.path.join(base_dir, file_path)
				if data.file_content_mode.search_replace_auto then
					local _file_changed, changes_info = aip.file.save_changes(file_path, file_change_content)
					if changes_info and changes_info.failed_changes then
						table.insert(files_changes_failed, { path = file_path, changes_info = changes_info })
					else
						table.insert(files_changed, file_path)
					end
				else
					aip.file.save(file_path, file_change_content)
					table.insert(files_changed, file_path)
				end
			else
				-- If no file path, we just append the content back to second_part
				second_part = second_part .. "\n" .. elem.content
			end
		end
	end

	return second_part, files_changed, files_changes_failed
end

-- Generates and saves a failure report and pins a warning task if any file changes failed.
function handle_failed_changes(files_changes_failed, data)
	if #files_changes_failed == 0 then return end

	-- NOTE: Legacy, we should get rel path now
	-- local ai_res_path = aip.path.diff(data.ai_responses_for_raw_path, CTX.WORKSPACE_DIR)
	-- local fail_report_path = aip.path.diff(data.last_file_change_fails_report_path, CTX.WORKSPACE_DIR)
	--
	local ai_res_path = data.ai_responses_for_raw_path
	local fail_report_path = data.last_file_change_fails_report_path


	local fail_report_content = "❗ Here are the file change search misses.\nSee full AI response at:\n" .. ai_res_path
	fail_report_content = fail_report_content .. "\n\n" .. "Below are the search misses by file:"

	local msg = "❗❗❗ Failed to apply some changes to file(s) ❗❗❗\n"
	for _, fc in ipairs(files_changes_failed) do
		local hunk_block = build_failed_hunk_report_block(fc)
		if hunk_block then
			msg = msg .. "\n\n" .. hunk_block
			fail_report_content = fail_report_content .. "\n\n" .. hunk_block
		else
			local cause = aip.text.truncate(fc.changes_info.failed_changes[1].reason, 1000, "...")
			msg = msg .. "\n- " .. fc.path .. " (failed changes: " .. #fc.changes_info.failed_changes ..
					", cause: " .. cause .. ")"

			fail_report_content = fail_report_content .. "\n\n# " .. fc.path .. "\n\nFailed searches:"
			for _, fail_change in ipairs(fc.changes_info.failed_changes) do
				local search_text = aip.text.truncate(fail_change.search, 1000, "...")
				fail_report_content = fail_report_content .. "\n\n````\n" .. search_text .. "\n````"
			end
		end
	end

	msg = msg .. "\n\nFor fail report, see file:\n➜ " .. fail_report_path
	msg = msg .. "\n\nFor full raw AI response, see file:\n➜ " .. ai_res_path

	aip.task.pin("changes_failed", 0, { label = "WARNING", content = msg })
	aip.file.append(data.last_file_change_fails_report_path, fail_report_content .. "\n\n")
end

-- ==== RETURN

return {
	process_ui_directives      = process_ui_directives,
	build_info_lines           = build_info_lines,
	build_changed_files_report = build_changed_files_report,
	apply_changes              = apply_changes,
	handle_failed_changes      = handle_failed_changes
}
