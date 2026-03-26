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

local function resolve_dev_chat_path(dev_chat_path, options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."

	if is_null(dev_chat_path) or dev_chat_path == "" then
		return coder_prompt_dir .. "/dev/chat/dev-chat.md"
	end

	local normalized_path = dev_chat_path:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if not has_extension then
		return normalized_path .. "/dev-chat.md"
	end

	return normalized_path
end

local function resolve_dev_spec_path(dev_spec_path, options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."

	if is_null(dev_spec_path) or dev_spec_path == "" then
		return coder_prompt_dir .. "/dev/spec/_spec-rules.md", coder_prompt_dir .. "/dev/spec/spec.md"
	end

	local normalized_path = dev_spec_path:gsub("/+$", "")
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

local function resolve_dev_plan_dir(dev_plan_dir, options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."
	local strict_dir = options.strict_dir == true

	if is_null(dev_plan_dir) or dev_plan_dir == "" then
		return coder_prompt_dir .. "/dev/plan"
	end

	local normalized_path = dev_plan_dir:gsub("/+$", "")
	local _dir, file_name = aip.path.split(normalized_path)
	local has_extension = file_name and file_name:match("^.+%.[^%.]+$") ~= nil
	if has_extension then
		if strict_dir then
			return nil, "Invalid dev.plan.dir, expected directory path, got file path: " .. normalized_path
		end
		local parent_dir = aip.path.parent(normalized_path)
		if is_null(parent_dir) or parent_dir == "" then
			return "."
		end
		return parent_dir:gsub("/+$", "")
	end

	return normalized_path
end

local function load_dev_chat_template_content()
	local template_path = CTX.AGENT_FILE_DIR .. "/templates/dev/chat/dev-chat.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end

	return
	"# Dev Chat\n\nAdd a new `## Request: _user_ask_title_concise_` with the answer below (concise title). Use markdown sub-headings for sub sections. Keep this top instruction in this file. \n"
end

local function ensure_dev_chat_file(dev_chat_path, options)
	options = options or {}
	local resolved_path = resolve_dev_chat_path(dev_chat_path, options)

	if aip.file.exists(resolved_path) then
		return resolved_path
	end

	local seed_content = options.seed_content
	if is_null(seed_content) and resolved_path:lower():match("%.md$") then
		seed_content = load_dev_chat_template_content()
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
	local template_path = CTX.AGENT_FILE_DIR .. "/templates/dev/plan/_plan-rules.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end
	return "# Plan Rules\n\n- Keep plans concise and actionable.\n"
end

local function ensure_dev_plan_file(dev_plan_dir, options)
	options = options or {}
	local resolved_dir, resolve_err = resolve_dev_plan_dir(dev_plan_dir, options)
	if is_null(resolved_dir) or resolved_dir == "" then
		return nil, nil, resolve_err or "Invalid dev.plan.dir"
	end

	local rules_path = resolved_dir .. "/_plan-rules.md"
	local ensure_res
	if aip.file.exists(rules_path) then
		ensure_res = aip.file.info(rules_path)
	else
		ensure_res = aip.file.ensure_exists(rules_path, load_dev_plan_rules_template_content())
	end

	if type(ensure_res) == "table" and ensure_res.error then
		return nil, nil, ensure_res.error
	end

	return resolved_dir, rules_path
end

local function load_dev_spec_rules_template_content()
	local template_path = CTX.AGENT_FILE_DIR .. "/templates/dev/spec/_spec-rules.md"
	local template_file = aip.file.load(template_path)
	if type(template_file) == "table" and type(template_file.content) == "string" and template_file.content ~= "" then
		return template_file.content
	end
	return "# Spec Rules\n\n- Keep specs clear and code-focused.\n"
end

local function ensure_dev_spec_file(dev_spec_path, options)
	options = options or {}
	local resolved_rules_path, resolved_spec_path = resolve_dev_spec_path(dev_spec_path, options)
	if is_null(resolved_rules_path) or resolved_rules_path == "" then
		return nil, nil, nil, "Invalid dev.spec.path"
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

return {
	filter_likely_text = filter_likely_text,
	list_likely_text = list_likely_text,
	list_likely_text_with_stats = list_likely_text_with_stats,
	list_load_likely_text = list_load_likely_text,
	resolve_dev_chat_path = resolve_dev_chat_path,
	resolve_dev_plan_dir = resolve_dev_plan_dir,
	resolve_dev_spec_path = resolve_dev_spec_path,
	load_dev_chat_template_content = load_dev_chat_template_content,
	ensure_dev_chat_file = ensure_dev_chat_file,
	ensure_dev_plan_file = ensure_dev_plan_file,
	ensure_dev_spec_file = ensure_dev_spec_file,
}
