local CONST = require("consts")

local M = {}

local TEMPLATES_DIR = CTX.AGENT_FILE_DIR .. "/templates"

function M.load_template(rel_path)
	return aip.file.load(TEMPLATES_DIR .. "/" .. rel_path)
end

-- Save a prompt file
-- `prompt_path`    - the destination file path
function M.save_prompt_file(prompt_path)
	local tmpl_path = TEMPLATES_DIR .. "/prompt-template.md"
	if not aip.path.exists(prompt_path) then
		local content = aip.file.load(tmpl_path).content

		-- Replace the placeholder with the actual README path
		local prompt_dir = aip.path.parent(prompt_path) or "."
		local readme_path = aip.path.join(prompt_dir, "README.md")
		content = content:gsub("PATH_TO_PRO_CODER_README", readme_path)

		aip.file.save(prompt_path, content)
	end
end

function M.init_fixed_files(prompt_dir)
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

	aip.run.pin("rfile", 1, {
		label   = CONST.LABEL_README_FILE,
		content = rel_dest_path .. addl_msg
	})

	-- init other files
	local files_to_init = {
		{
			src_path  = CTX.AGENT_FILE_DIR .. "/templates/dev/plan/_plan-rules.md",
			dest_path = prompt_dir .. "/dev/plan/_plan-rules.md"
		},
		{
			src_path  = CTX.AGENT_FILE_DIR .. "/templates/dev/chat/dev-chat.md",
			dest_path = prompt_dir .. "/dev/chat/dev-chat.md"
		}
	}

	for _, f in ipairs(files_to_init) do
		if not aip.path.exists(f.dest_path) then
			local content = aip.file.load(f.src_path).content
			aip.file.save(f.dest_path, content)
		end
	end
end

-- Concatenates the prompt parts with the AI response for prompt update.
function M.sync_prompt(first_part, ai_content_for_prompt)
	return aip.text.trim_end(first_part) .. "\n\n" .. ai_content_for_prompt
end

-- ==== Return

return M
