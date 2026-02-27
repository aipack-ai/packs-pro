-- === Public Functions

-- Returns {
--   code_map_dir: string,
--   code_map_file_path: string,
--   context_globs: string[],
--   structure_globs: string[],
--   user_prompt: string
-- }
local function extract_code_map_config(sub_input)
	local code_map_dir   = sub_input.coder_prompt_dir .. "/.code-map"

	-- by default the coder model
	local code_map_model = sub_input.coder_params.model
	if sub_input.agent_config.model then
		code_map_model = sub_input.agent_config.model
	end

	local code_map_input_concurrency = sub_input.coder_params.input_concurrency
	if sub_input.agent_config.input_concurrency then
		code_map_input_concurrency = sub_input.agent_config.input_concurrency
	end

	print("code_map_input_concurrency " .. code_map_input_concurrency)

	local user_prompt = sub_input.coder_prompt:find("%S") and sub_input.coder_prompt or nil
	return {
		code_map_dir               = code_map_dir,
		code_map_file_path         = code_map_dir .. "/code-map.json",
		context_globs              = sub_input.coder_params.context_globs,
		structure_globs            = sub_input.coder_params.structure_globs,
		user_prompt                = user_prompt,
		code_map_model             = code_map_model,
		code_map_input_concurrency = code_map_input_concurrency,
	}
end

-- Returns {
--   file_map: {[file_path: string]: {
--         mtime: number
--         summary: string,
--         when_to_use: string,
--      }
--   }
-- }
local function load_code_map_file(code_map_file_path)
	if aip.path.exists(code_map_file_path) then
		return aip.file.load_json(code_map_file_path)
	else
		return {
			file_map = {}
		}
	end
end

return {
	extract_code_map_config = extract_code_map_config,
	load_code_map_file      = load_code_map_file
}
