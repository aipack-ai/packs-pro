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
--   path_base_dir?: string,
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

local function normalize_code_map_path(file_path, path_base_dir)
	if not has_text(file_path) or not has_text(path_base_dir) then
		return file_path
	end

	local ok_file, resolved_file_path = pcall(aip.path.resolve, file_path)
	local ok_base, resolved_base_dir = pcall(aip.path.resolve, path_base_dir)
	if not ok_file or not ok_base then
		return file_path
	end
	if not has_text(resolved_file_path) or not has_text(resolved_base_dir) then
		return file_path
	end

	local normalized_base_dir = resolved_base_dir:gsub("/+$", "")
	local base_prefix = normalized_base_dir .. "/"
	if resolved_file_path:sub(1, #base_prefix) == base_prefix then
		local relative_path = aip.path.diff(resolved_file_path, normalized_base_dir)
		if has_text(relative_path) then
			return relative_path
		end
	end

	return file_path
end

local function append_path_lookup_key(keys, seen, key)
	if not has_text(key) then
		return
	end
	if not seen[key] then
		seen[key] = true
		table.insert(keys, key)
	end

	local normalized = key:gsub("^%./", "")
	if normalized ~= key and not seen[normalized] then
		seen[normalized] = true
		table.insert(keys, normalized)
	end
end

local function collect_path_lookup_keys(file_path, base_dirs)
	local keys = {}
	local seen = {}

	append_path_lookup_key(keys, seen, file_path)

	local lookup_base_dirs = {}
	local lookup_base_dirs_seen = {}
	local function append_base_dir(base_dir)
		if not has_text(base_dir) or lookup_base_dirs_seen[base_dir] then
			return
		end
		lookup_base_dirs_seen[base_dir] = true
		table.insert(lookup_base_dirs, base_dir)
	end

	if type(CTX) == "table" then
		append_base_dir(CTX.WORKSPACE_DIR)
	end

	if type(base_dirs) == "string" then
		append_base_dir(base_dirs)
	elseif type(base_dirs) == "table" then
		for _, base_dir in ipairs(base_dirs) do
			append_base_dir(base_dir)
		end
	end

	for _, base_dir in ipairs(lookup_base_dirs) do
		append_path_lookup_key(keys, seen, normalize_code_map_path(file_path, base_dir))

		local ok_diff, diff = pcall(aip.path.diff, file_path, base_dir)
		if ok_diff then
			append_path_lookup_key(keys, seen, diff)
		end

		local ok_file, resolved_file_path = pcall(aip.path.resolve, file_path)
		local ok_base, resolved_base_dir = pcall(aip.path.resolve, base_dir)
		if ok_file and ok_base and has_text(resolved_file_path) and has_text(resolved_base_dir) then
			local ok_resolved_diff, resolved_diff = pcall(aip.path.diff, resolved_file_path, resolved_base_dir)
			if ok_resolved_diff then
				append_path_lookup_key(keys, seen, resolved_diff)
			end
		end
	end

	return keys
end

local function find_file_map_entry(file_map, file_path, base_dirs)
	if type(file_map) ~= "table" then
		return nil
	end

	for _, key in ipairs(collect_path_lookup_keys(file_path, base_dirs)) do
		local mapped = file_map[key]
		if mapped ~= nil then
			return mapped
		end
	end

	return nil
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

	local path_base_dir = workbench_data_config.path_base_dir
	if not has_text(path_base_dir) and type(CTX) == "table" then
		path_base_dir = CTX.WORKSPACE_DIR
	end

	return {
		name = map_name,
		globs = globs,
		file_path = file_path,
		base_dir = data_dir,
		path_base_dir = path_base_dir,
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
				path_base_dir = nm.path_base_dir,
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
	normalize_code_map_path = normalize_code_map_path,

	-- consts
	LABEL_STATUS            = LABEL_STATUS,
	LABEL_RECOVERED         = LABEL_RECOVERED,
	WORKBENCH_DATA_MAP_NAME = WORKBENCH_DATA_MAP_NAME,
	WORKBENCH_DATA_MAP_GLOBS = WORKBENCH_DATA_MAP_GLOBS,
	collect_path_lookup_keys = collect_path_lookup_keys,
	find_file_map_entry = find_file_map_entry,
}
