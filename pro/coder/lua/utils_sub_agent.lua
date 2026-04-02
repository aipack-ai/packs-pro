local u_dev = require("dev")

-- === Support Functions
local MAX_SUB_AGENT_STEPS = 100

-- Properties that must be cleared from coder_params returned by sub-agents.
-- These are top-level config concerns and should not be merged back into pipeline state.
local CLEAR_CODER_PARAMS_RESPONSE_PROPERTIES = {
	"auto_context",
	"chat",
	"dev",
	"sub_agents",
}

-- Create a new sub_agent_config
-- NOTE: when item is a table, not realy validation for now, just make sure .enabled is default to true
-- TODO: when table should validate at lest that name is define
local function new_sub_agent_config(sub_agent_item, options)
	local item = sub_agent_item
	if type(item) == "string" then
		return { name = item, enabled = true, stage_pre = true, stage_post = false }
	elseif type(item) == "table" and item.name then
		if item.enabled == nil then
			item.enabled = true -- default true
		end
		if item.stage_pre == nil then
			item.stage_pre = true
		end
		if item.stage_post == nil then
			item.stage_post = false
		end
		if item.name == "pro@coder/dev" then
			local dev_config = u_dev.new_dev_sub_agent_config(item, options)
			if dev_config then
				if dev_config.enabled == nil then
					dev_config.enabled = true
				end
				if dev_config.stage_pre == nil then
					dev_config.stage_pre = true
				end
				if dev_config.stage_post == nil then
					dev_config.stage_post = false
				end
				return dev_config
			end
		end
		return item
	end
end

local function extract_sub_agent_configs(sub_agents, options)
	local configs = {}
	if type(sub_agents) ~= "table" then return configs end

	for _, item in ipairs(sub_agents) do
		local sub_agent_config = new_sub_agent_config(item, options)
		if sub_agent_config then
			table.insert(configs, sub_agent_config)
		end
	end
	return configs
end

local function clone_shallow(value)
	if type(value) ~= "table" then return value end
	return aip.lua.merge({}, value)
end

local function clone_history(history)
	return aip.lua.merge_deep({}, history)
end

local function new_dev_sub_agent_config(dev, options)
	return u_dev.new_dev_sub_agent_config(dev, options)
end

local function extract_coder_params(coder_meta)
	local params = {}
	aip.lua.merge_deep(params, coder_meta)
	params.sub_agents = nil
	return params
end

local function extract_sub_agent_response(run_res)
	if run_res.after_all ~= nil then
		return run_res.after_all
	end

	if run_res.outputs and #run_res.outputs > 0 then
		return run_res.outputs[1]
	end

	return nil
end

local function should_run_stage(config, stage)
	if config.enabled == false then
		return false
	end

	if stage == "pre" then
		return config.stage_pre ~= false
	end

	if stage == "post" then
		return config.stage_post == true
	end

	return true
end

-- === /Support Functions

-- === Public Interfaces

-- Runs a single sub-agent.
-- Returns modified params, modified prompt, and error message if any.
function run_sub_agent(config, stage, current_params, current_coder_prompt, coder_options, coder_prompt_dir)
	local opts = coder_options or {}
	local sub_agents_prev = opts.sub_agents_prev
	local sub_agents_next = opts.sub_agents_next
	opts.sub_agents_prev = nil
	opts.sub_agents_next = nil

	if config.enabled == false then
		return current_params, current_coder_prompt, nil
	end

	local coder_params_for_sub = extract_coder_params(current_params)
	local sub_input = {
		_display         = "sub agent input {coder_stage, coder_params, coder_prompt, agent_config, coder_prompt_dir, sub_agents_prev, sub_agents_next}",
		coder_stage      = stage,
		coder_params     = coder_params_for_sub,
		coder_prompt     = current_coder_prompt,
		coder_prompt_dir = coder_prompt_dir,
		agent_config     = config,
		sub_agents_prev  = sub_agents_prev,
		sub_agents_next  = sub_agents_next,
	}

	-- would be nil if no config.options, which is fine
	local config_options = aip.agent.extract_options(config.options)
	local options = aip.lua.merge_deep({}, opts, config_options)

	-- Run the agent with a single input in the list
	local run_res = aip.agent.run(config.name, {
		input = sub_input,
		options = options,
		agent_base_dir = CTX.WORKSPACE_DIR
	})

	if run_res == nil then
		return nil, nil, nil, "Sub-agent [" .. config.name .. "] execution failed (no response)"
	end

	local res = extract_sub_agent_response(run_res)
	local next_configs = nil

	-- If res is nil, it is considered success with no modifications to the state.
	if res == nil then return current_params, current_coder_prompt, next_configs end

	if type(res) ~= "table" then
		return nil, nil, nil, "Sub-agent [" .. config.name .. "] failed: invalid response type, expected table or nil"
	end

	-- Validate the response structure
	-- If success is false or error_msg is present, we stop execution
	if res.success == false or res.error_msg ~= nil then
		local err_msg = value_or(res.error_msg, "Unknown error")
		local full_err = "Sub-agent [" .. config.name .. "] failed: " .. err_msg
		if res.error_details then
			full_err = full_err .. "\nDetails: " .. res.error_details
		end
		return nil, nil, nil, full_err
	end

	-- Merge or replace state
	if res.coder_params then
		-- Clear config-level properties that sub-agents should not propagate
		for _, key in ipairs(CLEAR_CODER_PARAMS_RESPONSE_PROPERTIES) do
			res.coder_params[key] = nil
		end
		-- we merge here so, that the return value does not have to return unchanged things
		current_params = aip.lua.merge(current_params, res.coder_params)
	end
	if res.coder_prompt then
		current_coder_prompt = res.coder_prompt
	end

	if res.sub_agents_next ~= nil then
		next_configs = extract_sub_agent_configs(res.sub_agents_next, { coder_prompt_dir = coder_prompt_dir })
	end

	local agent_result = type(res) == "table" and res.agent_result or nil

	return current_params, current_coder_prompt, next_configs, agent_result
end

-- Executes a list of sub-agents for a specific stage.
-- Returns the modified meta and instruction string (derived from concatenated prompts).
function run_sub_agents(stage, coder_meta, inst, coder_options, coder_prompt_dir)
	-- Check AIPack version for sub-agent support
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.14") then
		return nil, nil, "Sub-agents require AIPack 0.8.15 or above (current: " .. CTX.AIPACK_VERSION .. ")"
	end

	local sub_agents = coder_meta.sub_agents

	local agent_configs = extract_sub_agent_configs(sub_agents, { coder_prompt_dir = coder_prompt_dir })
	if #agent_configs == 0 then
		return coder_meta, inst
	end

	local current_params = coder_meta
	current_params.sub_agents = nil -- for now remove this list (we might put the agent_configs later)

	-- Ensure glob parameters are tables if nil
	current_params.context_globs = value_or(current_params.context_globs, {})
	current_params.structure_globs = value_or(current_params.structure_globs, {})
	current_params.knowledge_globs = value_or(current_params.knowledge_globs, {})
	current_params.context_globs_pinned = value_or(current_params.context_globs_pinned, { pre = {}, post = {} })
	current_params.knowledge_globs_pinned = value_or(current_params.knowledge_globs_pinned, { pre = {}, post = {} })

	local current_coder_prompt = inst

	local executed = {}
	local i = 1
	local steps = 0

	while i <= #agent_configs do
		steps = steps + 1
		if steps > MAX_SUB_AGENT_STEPS then
			return nil, nil, "Sub-agent pipeline exceeded max steps (" .. MAX_SUB_AGENT_STEPS .. ")."
		end

		local config = agent_configs[i]
		if not should_run_stage(config, stage) then
			i = i + 1
			goto continue
		end
		local sub_agents_prev = clone_history(executed)
		local sub_agents_next = {}
		for j = i + 1, #agent_configs do
			table.insert(sub_agents_next, clone_shallow(agent_configs[j]))
		end

		local err
		local returned_next
		local agent_result
		current_params, current_coder_prompt, returned_next, agent_result, err = run_sub_agent(
			config,
			stage,
			current_params,
			current_coder_prompt,
			aip.lua.merge_deep({}, coder_options, {
				sub_agents_prev = sub_agents_prev,
				sub_agents_next = sub_agents_next
			}),
			coder_prompt_dir
		)
		if err then return nil, nil, err end

		table.insert(executed, {
			config = clone_shallow(config),
			sub_agent_result = agent_result,
			agent_result = agent_result
		})

		if returned_next ~= nil then
			local rebuilt = {}
			for k = 1, i do
				table.insert(rebuilt, agent_configs[k])
			end
			for _, cfg in ipairs(returned_next) do
				table.insert(rebuilt, cfg)
			end
			agent_configs = rebuilt
		end

		i = i + 1
		::continue::
	end

	local new_coder_meta = current_params
	-- put back the sub_agents
	new_coder_meta.sub_agents = agent_configs

	return new_coder_meta, current_coder_prompt
end

-- === /Public Interfaces

return {
	new_dev_sub_agent_config = new_dev_sub_agent_config,
	run_sub_agent  = run_sub_agent,
	run_sub_agents = run_sub_agents
}
