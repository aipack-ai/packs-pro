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
		aip.file.save(prompt_path, content)
	end
end

function M.init_fixed_files(prompt_dir)
	local files_to_init = {
		{
			src_path  = CTX.AGENT_FILE_DIR .. "/README.md",
			dest_path = prompt_dir .. "/README.md"
		},
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

-- ==== Return

return M
