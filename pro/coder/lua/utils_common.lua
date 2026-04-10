local function filter_likely_text(files)
	if files == nil or #files == 0 then
		return files
	end

	local first = files[1]
	if first.is_likely_text == nil then
		return files
	end

	local filtered = {}
	for _, f in ipairs(files) do
		if f.is_likely_text ~= false then
			table.insert(filtered, f)
		end
	end
	return filtered
end

local function list_likely_text(globs, options)
	local files = aip.file.list(globs, options)
	return filter_likely_text(files)
end

local function list_likely_text_with_stats(globs, options)
	local all_files = aip.file.list(globs, options)
	local filtered = filter_likely_text(all_files)
	local non_text_file_count = #all_files - #filtered
	if non_text_file_count < 0 then
		non_text_file_count = 0
	end
	return {
		files = filtered,
		non_text_file_count = non_text_file_count
	}
end

local function list_load_likely_text(globs, options)
	local files = aip.file.list_load(globs, options)
	return filter_likely_text(files)
end

local function resolve_workbench_root_dir(options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."
	local workbench_dir = options.workbench_dir

	if not is_null(workbench_dir) and workbench_dir ~= "" then
		return workbench_dir:gsub("/+$", "")
	end

	return coder_prompt_dir .. "/workbench-default"
end

local function resolve_workbench_chat_path(workbench_chat_path, options)
	options = options or {}
	local workbench_root_dir = resolve_workbench_root_dir(options)

	if is_null(workbench_chat_path) or workbench_chat_path == "" then
		return workbench_root_dir .. "/chat.md"
	end

	local normalized_path = workbench_chat_path:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if not has_extension then
		return normalized_path .. "/chat.md"
	end

	return normalized_path
end

local function resolve_workbench_plan_paths(workbench_plan_value, options)
	options = options or {}
	local workbench_root_dir = resolve_workbench_root_dir(options)

	if is_null(workbench_plan_value) or workbench_plan_value == "" then
		local dir = workbench_root_dir
		return dir, dir .. "/_plan-rules.md", dir .. "/plan.md"
	end

	local normalized_path = workbench_plan_value:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if has_extension then
		local plan_path = normalized_path
		local dir = aip.path.parent(plan_path)
		if is_null(dir) or dir == "" then
			dir = "."
		end
		return dir, dir .. "/_plan-rules.md", plan_path
	end

	local dir = normalized_path
	return dir, dir .. "/_plan-rules.md", dir .. "/plan.md"
end

local function is_same_path(path_a, path_b)
	if is_null(path_a) or is_null(path_b) then
		return false
	end
	local normalized_a = tostring(path_a):gsub("/+$", "")
	local normalized_b = tostring(path_b):gsub("/+$", "")
	return normalized_a == normalized_b
end

local function resolve_workbench_spec_path(workbench_spec_path, options)
	options = options or {}
	local workbench_root_dir = resolve_workbench_root_dir(options)

	if is_null(workbench_spec_path) or workbench_spec_path == "" then
		return workbench_root_dir .. "/_spec-rules.md", workbench_root_dir .. "/spec.md"
	end

	local normalized_path = workbench_spec_path:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if not has_extension then
		return normalized_path .. "/_spec-rules.md", normalized_path .. "/spec.md"
	end

	local spec_dir = aip.path.parent(normalized_path)
	if is_null(spec_dir) or spec_dir == "" then
		spec_dir = "."
	end
	return spec_dir .. "/_spec-rules.md", normalized_path
end

local function resolve_workbench_plan_dir(workbench_plan_dir, options)
	options = options or {}
	local strict_dir = options.strict_dir == true
	local workbench_root_dir = resolve_workbench_root_dir(options)

	if is_null(workbench_plan_dir) or workbench_plan_dir == "" then
		return workbench_root_dir
	end

	local normalized_path = workbench_plan_dir:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if has_extension then
		if strict_dir then
			return nil, "Invalid workbench.plan.dir, expected directory path, got file path: " .. normalized_path
		end
		local parent_dir = aip.path.parent(normalized_path)
		if is_null(parent_dir) or parent_dir == "" then
			return "."
		end
		return parent_dir:gsub("/+$", "")
	end

	return normalized_path
end

local function load_workbench_chat_template_content()
	local template_path = CTX.AGENT_FILE_DIR .. "/workbench-templates/chat.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end

	return
	"# Dev Chat\n\nAdd a new `## Request: _user_ask_title_concise_` with the answer below (concise title). Use markdown sub-headings for sub sections. Keep this top instruction in this file. \n"
end

local function ensure_workbench_chat_file(workbench_chat_path, options)
	options = options or {}
	local resolved_path = resolve_workbench_chat_path(workbench_chat_path, options)

	if aip.file.exists(resolved_path) then
		return resolved_path
	end

	-- FOR LEGACY SUPPORT
	local resolved_dir = aip.path.parent(resolved_path)
	if is_null(resolved_dir) or resolved_dir == "" then
		resolved_dir = "."
	end
	local legacy_same_dir_chat_path = resolved_dir .. "/dev-chat.md"
	if aip.file.exists(legacy_same_dir_chat_path) then
		local move_same_dir_res = aip.file.move(legacy_same_dir_chat_path, resolved_path, { overwrite = false })
		if type(move_same_dir_res) == "table" and move_same_dir_res.error then
			return nil, move_same_dir_res.error
		end
		return resolved_path
	end

	-- FOR LEGACY SUPPORT
	local coder_prompt_dir = options.coder_prompt_dir or "."
	local legacy_default_chat_path = coder_prompt_dir .. "/dev/chat/dev-chat.md"
	local workspace_default_chat_path = coder_prompt_dir .. "/workspace-default/chat.md"
	if is_same_path(resolved_path, workspace_default_chat_path) and aip.file.exists(legacy_default_chat_path) then
		local move_default_res = aip.file.move(legacy_default_chat_path, resolved_path, { overwrite = false })
		if type(move_default_res) == "table" and move_default_res.error then
			return nil, move_default_res.error
		end
		return resolved_path
	end

	local seed_content = options.seed_content
	if is_null(seed_content) and resolved_path:lower():match("%.md$") then
		seed_content = load_workbench_chat_template_content()
	end

	local ensure_res = nil
	if not is_null(seed_content) then
		ensure_res = aip.file.ensure_exists(resolved_path, seed_content)
	else
		ensure_res = aip.file.ensure_exists(resolved_path)
	end

	if type(ensure_res) == "table" and ensure_res.error then
		return nil, ensure_res.error
	end

	return resolved_path
end

local function load_dev_plan_rules_template_content()
	local template_path = CTX.AGENT_FILE_DIR .. "/workbench-templates/_plan-rules.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end
	return "# Plan Rules\n\n- Keep plans concise and actionable.\n"
end

local function ensure_workbench_plan_file(workbench_plan_dir, options)
	options = options or {}
	local resolved_dir, rules_path, plan_path = resolve_workbench_plan_paths(workbench_plan_dir, options)
	local resolve_err = nil
	if is_null(resolved_dir) or resolved_dir == "" then
		return nil, nil, resolve_err or "Invalid workbench.plan.dir"
	end

	local ensure_res
	if aip.file.exists(rules_path) then
		ensure_res = aip.file.info(rules_path)
	else
		ensure_res = aip.file.ensure_exists(rules_path, load_dev_plan_rules_template_content())
	end

	if type(ensure_res) == "table" and ensure_res.error then
		return nil, nil, ensure_res.error
	end

	local ensure_plan_res
	if aip.file.exists(plan_path) then
		ensure_plan_res = aip.file.info(plan_path)
	else
		ensure_plan_res = aip.file.ensure_exists(plan_path)
	end

	if type(ensure_plan_res) == "table" and ensure_plan_res.error then
		return nil, nil, nil, ensure_plan_res.error
	end

	return resolved_dir, rules_path, plan_path
end

local function load_dev_spec_rules_template_content()
	local template_path = CTX.AGENT_FILE_DIR .. "/workbench-templates/_spec-rules.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end
	return "# Spec Rules\n\n- Keep specs clear and code-focused.\n"
end

local function ensure_workbench_spec_file(workbench_spec_path, options)
	options = options or {}
	local resolved_rules_path, resolved_spec_path = resolve_workbench_spec_path(workbench_spec_path, options)
	if is_null(resolved_rules_path) or resolved_rules_path == "" then
		return nil, nil, nil, "Invalid workbench.spec.path"
	end

	local rules_path = resolved_rules_path
	local spec_path = resolved_spec_path
	if is_null(spec_path) or spec_path == "" then
		local spec_dir = aip.path.parent(rules_path)
		if is_null(spec_dir) or spec_dir == "" then
			spec_dir = "."
		end
		spec_path = spec_dir .. "/spec.md"
	end

	local ensure_spec_res
	if aip.file.exists(rules_path) then
		ensure_spec_res = aip.file.info(rules_path)
	else
		ensure_spec_res = aip.file.ensure_exists(rules_path, load_dev_spec_rules_template_content())
	end

	if type(ensure_spec_res) == "table" and ensure_spec_res.error then
		return nil, nil, nil, ensure_spec_res.error
	end

	local ensure_context_res
	if aip.file.exists(spec_path) then
		ensure_context_res = aip.file.info(spec_path)
	else
		ensure_context_res = aip.file.ensure_exists(spec_path)
	end

	if type(ensure_context_res) == "table" and ensure_context_res.error then
		return nil, nil, nil, ensure_context_res.error
	end

	return rules_path, spec_path, spec_path
end

local function workbench_legacy_file_migrate(options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."
	local legacy_chat_path = coder_prompt_dir .. "/dev/chat/dev-chat.md"
	local migrated_chat_path = coder_prompt_dir .. "/workbench-default/chat.md"

	if not aip.file.exists(legacy_chat_path) then
		return nil
	end

	if aip.file.exists(migrated_chat_path) then
		return migrated_chat_path
	end

	local move_res = aip.file.move(legacy_chat_path, migrated_chat_path, { overwrite = false })
	if type(move_res) == "table" and move_res.error then
		return nil, move_res.error
	end

	return migrated_chat_path
end

return {
	filter_likely_text = filter_likely_text,
	list_likely_text = list_likely_text,
	list_likely_text_with_stats = list_likely_text_with_stats,
	list_load_likely_text = list_load_likely_text,
	resolve_workbench_root_dir = resolve_workbench_root_dir,
	resolve_workbench_chat_path = resolve_workbench_chat_path,
	resolve_workbench_plan_dir = resolve_workbench_plan_dir,
	resolve_workbench_plan_paths = resolve_workbench_plan_paths,
	resolve_workbench_spec_path = resolve_workbench_spec_path,
	load_workbench_chat_template_content = load_workbench_chat_template_content,
	ensure_workbench_chat_file = ensure_workbench_chat_file,
	ensure_workbench_plan_file = ensure_workbench_plan_file,
	ensure_workbench_spec_file = ensure_workbench_spec_file,
	workbench_legacy_file_migrate = workbench_legacy_file_migrate,
	resolve_dev_root_dir = resolve_workbench_root_dir,
	resolve_dev_chat_path = resolve_workbench_chat_path,
	resolve_dev_plan_dir = resolve_workbench_plan_dir,
	resolve_dev_spec_path = resolve_workbench_spec_path,
	load_dev_chat_template_content = load_workbench_chat_template_content,
	ensure_dev_chat_file = ensure_workbench_chat_file,
	ensure_dev_plan_file = ensure_workbench_plan_file,
	ensure_dev_spec_file = ensure_workbench_spec_file,
	dev_legal_file_migrate = workbench_legacy_file_migrate,
}
