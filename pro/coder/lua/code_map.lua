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
--      globs?:  string[],
--      named_maps?: { name: string, globs: string[] }[],
--      model?: string,
--      input_concurrency?: number
--   }
-- }

-- type MapDef = {
--   name: string | nil,
--   globs: string[],
--   file_path: string
-- }

-- type CodeMapConfig = {
--   code_map_dir: string,
--   map_defs: MapDef[],
--   all_globs: string[],
--   user_prompt: string
--   model: string,
--   input_concurrency: number,
-- }

-- - sub_input: CodeMapInput
-- - return: CodeMapConfig
local function extract_code_map_config(sub_input)
	local agent_config = sub_input.agent_config
	local code_map_dir = sub_input.coder_prompt_dir .. "/.cache/code-map"

	if not agent_config.globs and not agent_config.named_maps then
		error("code map agent config require a `globs: string[]` or `named_maps` property")
	end

	-- by default the coder model
	local code_map_model = sub_input.coder_params.model
	if agent_config.model then
		code_map_model = agent_config.model
	end


	local code_map_input_concurrency = DEFAULT_INPUT_CONCURRENCY
	if agent_config.input_concurrency then
		code_map_input_concurrency = agent_config.input_concurrency
	end

	local user_prompt = sub_input.coder_prompt:find("%S") and sub_input.coder_prompt or nil

	local map_defs = {}
	local all_globs_set = {}
	local all_globs = {}

	local function add_globs(globs)
		for _, g in ipairs(globs) do
			if not all_globs_set[g] then
				all_globs_set[g] = true
				table.insert(all_globs, g)
			end
		end
	end

	if agent_config.globs then
		table.insert(map_defs, {
			name = nil,
			globs = agent_config.globs,
			file_path = code_map_dir .. "/code-map.json"
		})
		add_globs(agent_config.globs)
	end

	if agent_config.named_maps then
		for _, nm in ipairs(agent_config.named_maps) do
			table.insert(map_defs, {
				name = nm.name,
				globs = nm.globs,
				file_path = code_map_dir .. "/" .. nm.name .. "-code-map.json"
			})
			add_globs(nm.globs)
		end
	end

	return {
		code_map_dir       = code_map_dir,
		map_defs           = map_defs,
		all_globs          = all_globs,
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
