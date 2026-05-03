-- === Consts
local DEFAULT_INPUT_CONCURRENCY = 8
local u_common = require("utils_common")

local LABEL_STATUS              = "   Status:"
local LABEL_RECOVERED           = "Recovered:"
local WORKBENCH_DATA_MAP_NAME   = "data"
local WORKBENCH_DATA_MAP_GLOBS  = { "**/*.*" }

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
--      workbench_data?: table | boolean,
--      model?: string,
--      input_concurrency?: number
--   }
-- }

-- type MapDef = {
--   name: string | nil,
--   globs: string[],
--   file_path: string,
--   base_dir?: string,
-- }

-- type CodeMapConfig = {
--   code_map_dir: string,
--   map_defs: MapDef[],
--   all_globs: string[],
--   user_prompt: string
--   model: string,
--   input_concurrency: number,
-- }

local function has_text(value)
	return type(value) == "string" and value ~= ""
end

local function clone_array(values)
	local out = {}
	if type(values) ~= "table" then
		return out
	end
	for _, value in ipairs(values) do
		table.insert(out, value)
	end
	return out
end

local function new_workbench_data_named_map(workbench_data_config)
	if is_null(workbench_data_config) or type(workbench_data_config) ~= "table" then
		return nil
	end

	local data_dir = workbench_data_config.data_dir
	if not has_text(data_dir) then
		data_dir = workbench_data_config.base_dir
	end

	local file_path = workbench_data_config.file_path
	local cache_dir = workbench_data_config.cache_dir
	if not has_text(file_path) and has_text(cache_dir) then
		file_path = cache_dir .. "/code-map/" .. WORKBENCH_DATA_MAP_NAME .. "-code-map.json"
	end

	if not has_text(data_dir) or not has_text(file_path) then
		return nil
	end

	local map_name = workbench_data_config.name
	if not has_text(map_name) then
		map_name = WORKBENCH_DATA_MAP_NAME
	end

	local globs = clone_array(workbench_data_config.globs)
	if #globs == 0 then
		globs = clone_array(WORKBENCH_DATA_MAP_GLOBS)
	end

	return {
		name = map_name,
		globs = globs,
		file_path = file_path,
		base_dir = data_dir,
	}
end

-- - sub_input: CodeMapInput
-- - return: CodeMapConfig
local function extract_code_map_config(sub_input)
	local agent_config = sub_input.agent_config
	-- Use agent_config.cache_dir if provided, else default
	local code_map_dir = agent_config.cache_dir or (sub_input.coder_prompt_dir .. "/.cache/code-map")
	local base_dir = agent_config.base_dir -- can be nil

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
			file_path = code_map_dir .. "/code-map.json",
			base_dir = base_dir,
		})
		add_globs(agent_config.globs)
	end

	if agent_config.named_maps then
		for _, nm in ipairs(agent_config.named_maps) do
			table.insert(map_defs, {
				name = nm.name,
				globs = nm.globs,
				file_path = nm.file_path or (code_map_dir .. "/" .. nm.name .. "-code-map.json"),
				base_dir = nm.base_dir or base_dir,
			})
			add_globs(nm.globs)
		end
	end

	local workbench_data_config = agent_config.workbench_data
	if workbench_data_config == true then
		workbench_data_config = sub_input.coder_workbench
	end
	local workbench_data_map = new_workbench_data_named_map(workbench_data_config)
	if workbench_data_map then
		table.insert(map_defs, workbench_data_map)
		add_globs(workbench_data_map.globs)
	end

	return {
		code_map_dir      = code_map_dir,
		map_defs          = map_defs,
		all_globs         = all_globs,
		user_prompt       = user_prompt,
		model             = code_map_model,
		input_concurrency = code_map_input_concurrency,
		base_dir          = base_dir,
	}
end

-- Returns {
--   file_map: {[file_path: string]: {
--         mtime: number
--         hash: string,
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

-- - files: T[]
-- - return: { files: T[], non_text_file_count: number }
local function filter_text_files(files)
	local input_files = files or {}
	local out_files = u_common.filter_likely_text(input_files) or {}
	local non_text_file_count = #input_files - #out_files
	if non_text_file_count < 0 then
		non_text_file_count = 0
	end
	return {
		files = out_files,
		non_text_file_count = non_text_file_count
	}
end

return {
	extract_code_map_config = extract_code_map_config,
	load_code_map_file      = load_code_map_file,
	filter_text_files       = filter_text_files,
	new_workbench_data_named_map = new_workbench_data_named_map,

	-- consts
	LABEL_STATUS            = LABEL_STATUS,
	LABEL_RECOVERED         = LABEL_RECOVERED,
	WORKBENCH_DATA_MAP_NAME = WORKBENCH_DATA_MAP_NAME,
	WORKBENCH_DATA_MAP_GLOBS = WORKBENCH_DATA_MAP_GLOBS,
}
