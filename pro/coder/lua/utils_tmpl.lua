local CONST = require("consts")
local u_common = require("utils_common")

local M = {}

local TEMPLATES_DIR = CTX.AGENT_FILE_DIR .. "/templates"
local DEFAULT_TEMPLATES_DIR = CTX.AGENT_FILE_DIR .. "/templates-default"

function M.load_template(rel_path)
	return aip.file.load(TEMPLATES_DIR .. "/" .. rel_path)
end

local function load_existing_file(path)
	if is_null(path) or path == "" or not aip.file.exists(path) then
		return nil
	end

	local file = aip.file.load(path)
	if type(file) == "table" and file.error then
		return nil, file.error
	end

	return file
end

function M.load_user_template(prompt_dir, rel_path, options)
	options = options or {}
	if is_null(rel_path) or rel_path == "" then
		return nil, "Invalid user template path"
	end

	local normalized_rel_path = tostring(rel_path):gsub("^/+", "")
	if not is_null(prompt_dir) and prompt_dir ~= "" then
		for _, template_dir in ipairs({ "templates-user", "templates-default" }) do
			local prompt_template_path = tostring(prompt_dir):gsub("/+$", "") .. "/" .. template_dir .. "/" .. normalized_rel_path
			local prompt_template, prompt_template_err = load_existing_file(prompt_template_path)
			if prompt_template_err then
				return nil, prompt_template_err
			end
			if prompt_template then
				return prompt_template
			end
		end
	end

	local fallback_path = options.fallback_path
	if not is_null(fallback_path) and fallback_path ~= "" then
		local fallback_template, fallback_template_err = load_existing_file(fallback_path)
		if fallback_template_err then
			return nil, fallback_template_err
		end
		if fallback_template then
			return fallback_template
		end
	end

	return nil, "User template not found: " .. normalized_rel_path
end

function M.load_suggest_commit_template(prompt_dir)
	return M.load_user_template(prompt_dir, "suggest-commit.md")
end


-- Save a prompt file
-- `prompt_path`    - the destination file path
function M.save_prompt_file(prompt_path)
	local tmpl_path = TEMPLATES_DIR .. "/prompt-template.md"
	if not aip.path.exists(prompt_path) then
		local content = aip.file.load(tmpl_path).content

		-- Replace the placeholder with the actual coder dir path
		local prompt_dir = aip.path.parent(prompt_path) or "."
		content = content:gsub("PATH_TO_PRO_CODER_DIR", prompt_dir)

		aip.file.save(prompt_path, content)
	end
end

function M.init_user_templates(prompt_dir)
	local legacy_dir = prompt_dir .. "/user-templates"
	local archive_dir = prompt_dir .. "/deprecated-user-templates"
	if aip.file.exists(legacy_dir) then
		local archive_path = archive_dir
		if aip.path.exists(archive_dir) then
			archive_path = archive_dir .. "/user-templates-" .. aip.uuid.new_v4()
		end
		local move_res = aip.file.move(legacy_dir, archive_path, { overwrite = false })
		if type(move_res) == "table" and move_res.error then
			return nil, move_res.error
		end
	end
	if aip.file.exists(archive_dir) then
		local archive_readme_res = aip.file.ensure_exists(archive_dir .. "/README.md",
			"# Deprecated User Templates\n\nThis directory is no longer used. Its files are preserved only in case they contain earlier customizations. Copy any customizations you want to keep into the sibling `templates-user/` directory using the matching template filenames. This directory can be deleted.\n")
		if type(archive_readme_res) == "table" and archive_readme_res.error then
			return nil, archive_readme_res.error
		end
	end

	for _, dir_name in ipairs({ "templates-default", "templates-user" }) do
		local ensure_dir_res = aip.file.ensure_dir(prompt_dir .. "/" .. dir_name)
		if type(ensure_dir_res) == "table" and ensure_dir_res.error then
			return nil, ensure_dir_res.error
		end
	end

	local template_files = aip.file.list(DEFAULT_TEMPLATES_DIR .. "/template-*")
	if type(template_files) == "table" and template_files.error then
		return nil, template_files.error
	end
	for _, template_file in ipairs(template_files) do
		local dest_name = template_file.name:gsub("^template%-", "", 1)
		if dest_name ~= template_file.name then
			local dest_path = prompt_dir .. "/templates-default/" .. dest_name
			local sync_res
			if aip.file.copy then
				sync_res = aip.file.copy(template_file.path, dest_path, { overwrite = true })
			else
				local template = aip.file.load(template_file.path)
				if type(template) == "table" and template.error then
					return nil, template.error
				end
				sync_res = aip.file.save(dest_path, template.content)
			end
			if type(sync_res) == "table" and sync_res.error then
				return nil, sync_res.error
			end
		end
	end

	return true
end

function M.init_fixed_files(prompt_dir)
	local user_templates_ok, user_templates_err = M.init_user_templates(prompt_dir)
	if not user_templates_ok then
		error(user_templates_err)
	end

	-- init README if needed
	local readme_orig = aip.file.info(CTX.AGENT_FILE_DIR .. "/README.md")
	local readme_dest_path = prompt_dir .. "/README.md"
	local readme_dest = aip.file.info(readme_dest_path)

	local readme_orig_ctime = readme_orig and readme_orig.ctime or 0
	local readme_dest_ctime = readme_dest and readme_dest.ctime or 0

	local rel_dest_path = readme_dest_path

	local addl_msg = ""
	if readme_orig and readme_orig_ctime > readme_dest_ctime then
		if aip.file.copy then
			-- since 0.8.15
			aip.file.copy(readme_orig.path, readme_dest_path, { overwrite = true })
		else
			-- legacy
			local content = aip.file.load(readme_orig.path).content
			aip.file.save(readme_dest_path, content)
		end

		if readme_dest_ctime == 0 then
			addl_msg = "\n(created)"
		else
			addl_msg = "\n(updated)"
		end
	end

	aip.run.pin("rfile", 5, {
		label   = CONST.LABEL_README_FILE,
		content = rel_dest_path .. addl_msg
	})

	u_common.dev_legal_file_migrate({ coder_prompt_dir = prompt_dir })
end

-- Concatenates the prompt parts with the AI response for prompt update.
function M.sync_prompt(first_part, ai_content_for_prompt)
	return aip.text.trim_end(first_part) .. "\n\n" .. ai_content_for_prompt
end

-- ==== Return

return M
