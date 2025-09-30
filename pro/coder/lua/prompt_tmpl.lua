

local TEMPLATES_DIR = CTX.AGENT_FILE_DIR .. "/templates"

-- ==== Support Functions

-- Save the For each template_files, if the file name is not int he dest_dir, will copy it
-- `dest_dir`       - e.g., .aipack/.prompt/pro@coder/dev/plan
-- `template_files` - e.g., 
-- 
-- NOTE: Support only one level at this time (and assume .md)
function save_template_files(template_files, dest_dir)
  -- Compute the existing files map by file.name
  local existing_files_list = aip.file.list(dest_dir .. "/*.md")
  local existing_files_map = {}
  for _, f in ipairs(existing_files_list) do
    existing_files_map[f.name] = true
  end

  -- For each template files, copy if not already there
  for _, f in ipairs(template_files) do
    if not existing_files_map[f.name] then
      local content = aip.file.load(f.path).content
      local dest_path = dest_dir .. "/" .. f.name
      local dest_file = aip.file.save(dest_path, content)
      print("dev plan file saved: " .. dest_path)
    end
  end

end



-- ==== Public APIs

-- Save a prompt file
-- `prompt_path`    - the destination file path
function save_prompt_file(prompt_path)
  local tmpl_path = TEMPLATES_DIR .. "/prompt-template.md"
  if not aip.path.exists(prompt_path) then
      local content = aip.file.load(tmpl_path).content
      aip.file.save(prompt_path, content)
  end
end

function init_fixed_files(prompt_dir)
  local files_to_init = {
    { src_path  = CTX.AGENT_FILE_DIR .. "/README.md",
      dest_path = prompt_dir .. "/README.md"
    },
    {
      src_path  = CTX.AGENT_FILE_DIR .. "/templates/dev/plan/_plan-rules.md",
      dest_path = prompt_dir .. "/dev/plan/_plan-rules.md"
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

return {
  save_prompt_file    = save_prompt_file,
  init_fixed_files    = init_fixed_files,
}


