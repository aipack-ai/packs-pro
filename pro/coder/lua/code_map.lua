-- === Consts
local DEFAULT_INPUT_CONCURRENCY = 8

-- === Public Functions

-- type CodeMapInput = {
--   coder_prompt_dir: string,
--   coder_params: { // only a subset needed
--      model?: string,
--      input_concurrency?: number,
--   },
--   agent_config: {
--      globs:  string[], // require
--      model?: string, // will override sub_input.coder_params.model
--      input_concurrency?: string
--   }
-- }

-- type CodeMapConfig = {
--   code_map_dir: string,
--   code_map_file_path: string,
--   globs: string[],
--   user_prompt: string
-- }

-- - sub_input: CodeMapInput
-- - return: CodeMapConfig
local function extract_code_map_config(sub_input)
	local agent_config = sub_input.agent_config
	local code_map_dir = sub_input.coder_prompt_dir .. "/.cache/code-map"

	if not agent_config.globs then
		error("code map agent config require a `globs: string[]` property")
	end

	-- by default the coder model
	local code_map_model = sub_input.coder_params.model
	if sub_input.agent_config.model then
		code_map_model = sub_input.agent_config.model
	end


	local code_map_input_concurrency = DEFAULT_INPUT_CONCURRENCY
	if sub_input.agent_config.input_concurrency then
		code_map_input_concurrency = sub_input.agent_config.input_concurrency
	end

	local user_prompt = sub_input.coder_prompt:find("%S") and sub_input.coder_prompt or nil
	return {
		code_map_dir       = code_map_dir,
		code_map_file_path = code_map_dir .. "/code-map.json",
		globs              = sub_input.coder_params.context_globs,
		user_prompt        = user_prompt,
		model              = code_map_model,
		input_concurrency  = code_map_input_concurrency,
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
