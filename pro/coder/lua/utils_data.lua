local p_tmpl           = require("utils_tmpl")
local PROMPT_FILE_NAME = "coder-prompt.md"

-- Returns FileRecord
function prep_prompt_file(input, options)
	options                   = options or {}
	local default_prompt_path = options.default_prompt_path
	local add_separator       = options.add_separator ~= nil and options.add_separator or false
	-- Enter prompt_path
	local prompt_path         = nil
	if input == nil then
		prompt_path = default_prompt_path
	elseif type(input) == "string" then
		-- remove the trailing /
		prompt_path = input:gsub("/+$", "")
		prompt_path = aip.text.ensure(input, { prefix = "./", suffix = "/" .. PROMPT_FILE_NAME })
	else
		prompt_path = input.path
	end

	-- Get flag
	local first_time = aip.path.exists(prompt_path) ~= true

	-- aip.file.ensure_exists(prompt_path, initial_content, {content_when_empty =  true})
	p_tmpl.save_prompt_file(prompt_path)

	-- DISABLE for now (should use `aip.editor.open_file(prompt_path)` when implemented)
	-- if first_time then
	--   ok, err = pcall(aip.cmd.exec,"code", {prompt_path})
	-- end

	return aip.file.load(prompt_path)
end

-- returns `inst, content` and each can be nil
-- options {content_is_default = bool}
--   - When content_is_default, it means that if no two parts, the content will be the first_part
function prep_inst_and_content(content, separator, options)
	local content_is_default = options and options.content_is_default or false
	-- for v0.7.10 compatibilty
	local first_part, second_part = nil, nil
	if aip.text.split_first_line then -- this is new in 0.7.11 (better, more robust with others =====)
		first_part, second_part = aip.text.split_first_line(content, separator)
	else
		first_part, second_part = aip.text.split_first(content, separator .. "\n")
	end

	local inst, content = nil, nil
	if second_part ~= nil then
		inst = first_part
		content = second_part
	elseif content_is_default then
		content = first_part
	else
		inst = first_part
	end

	return inst, content
end

-- This loads maps the FileMeta array as a FileRecord array by loading each file
-- It also augments the FileRecord with `.comment_file_path` (.e.g., "// file: some/path/to/file.ext")
-- returns nil if refs is nil
function load_file_refs(base_dir, refs)
	local files = nil
	if refs ~= nil then
		files = {}
		for _, file_ref in ipairs(refs) do
			local file = aip.file.load(file_ref.path, { base_dir = base_dir })
			-- Augment the file with the comment file path
			file.comment_file_path = aip.code.comment_line(file.ext, "file: " .. file.path)
			table.insert(files, file)
		end
	end
	return files
end

-- Do a shallow clone, and optionally merge the to_merge table
-- original: (required) The original table to copy
-- to_merge: (optional) The optional table to merge
function shallow_copy(original, to_merge)
	local copy = {}

	-- First, copy all elements from original
	for k, v in pairs(original) do
		copy[k] = v
	end

	-- If to_merge is provided, override/add elements
	if to_merge then
		for k, v in pairs(to_merge) do
			copy[k] = v
		end
	end

	return copy
end

function file_refs_to_md(refs, preamble)
	-- if refs nil or empty return nil
	if refs == nil or #refs == 0 then
		return "None"
	end
	preample = preamble and preamble .. "\n\n" or ""

	-- otehrwise, return a text with `- ref.path`
	local lines = {}
	for _, ref in ipairs(refs) do
		table.insert(lines, "- " .. ref.path)
	end
	return preample .. table.concat(lines, "\n")
end

-- Will resolve a list of string or array of string (each item can be anything)
-- If the item is a string, it will will be added to the root_working_refs array
--    (and then, we will do a aip.file.list(...) )
-- If the items is a string[], then,
-- Arguments:
-- - `working_globs: (string | string[])[]` - List of string or array of string
-- Returns:
-- - `FileInfo[][]` - List of file refs
function compute_working_refs_list(working_globs, base_dir)
	local root_working_globs    = nil
	local grouped_working_globs = nil

	local list_opts             = base_dir and { base_dir = base_dir } or nil
	local function list_files(globs)
		if list_opts then
			return aip.file.list(globs, list_opts)
		end
		return aip.file.list(globs)
	end

	for _, item in ipairs(working_globs) do
		if type(item) == "string" then
			root_working_globs = root_working_globs or {}
			table.insert(root_working_globs, item)
		elseif type(item) == "table" then
			-- NOTE: Assume item is list of string
			-- TODO: Check item is list of string
			grouped_working_globs = grouped_working_globs or {}
			table.insert(grouped_working_globs, item)
		end
	end

	local result = nil

	-- For the root working blobs, populate the result (item become {item})
	if root_working_globs then
		result = result or {}
		local root_files = list_files(root_working_globs)
		for _, f in ipairs(root_files) do
			table.insert(result, { f })
		end
	end

	-- For the grouped_working_globs, we add the files as one item
	if grouped_working_globs then
		result = result or {}
		for _, group in ipairs(grouped_working_globs) do
			local group_files = list_files(group)
			if #group_files > 0 then
				table.insert(result, group_files)
			end
		end
	end

	return result
end

-- true true if not empty, or nil, or userdata (pointer)
function is_not_empty(val)
	if type(val) == "userdata" then
		return false
	end
	if val == nil then
		return false
	end
	if val == "" then
		return false
	end
	if type(val) == "table" then
		return next(val) ~= nil
	end
	return true
end

return {
	prep_prompt_file          = prep_prompt_file,
	prep_inst_and_content     = prep_inst_and_content,
	load_file_refs            = load_file_refs,
	compute_working_refs_list = compute_working_refs_list,
	file_refs_to_md           = file_refs_to_md,
	is_not_empty              = is_not_empty,
}
