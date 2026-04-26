local CONST = require("consts")
local u_workbench = require("workbench")

-- === Support Functions
local MAX_SUB_AGENT_STEPS = 100

-- Properties that must be cleared from coder_params returned by sub-agents.
-- These are top-level config concerns and should not be merged back into pipeline state.
local CLEAR_CODER_PARAMS_RESPONSE_PROPERTIES = {
	"auto_context",
	"chat",
	"workbench",
	"dev",
	"sub_agents",
}

-- Create a new sub_agent_config
-- NOTE: when item is a table, not realy validation for now, just make sure .enabled is default to true
-- TODO: when table should validate at lest that name is define
local function new_sub_agent_config(sub_agent_item, options)
	local item = sub_agent_item
	if type(item) == "string" then
		return { name = item, enabled = true, on = "start" }
	elseif type(item) == "table" and item.name then
		if item.enabled == nil then
			item.enabled = true -- default true
		end
		if item.on == nil then
			item.on = "start"
		end
		if item.name == "pro@coder/dev" or item.name == "pro@coder/workbench" then
			local workbench_config = u_workbench.new_workbench_sub_agent_config(item, options)
			if workbench_config then
				if item.name == "pro@coder/dev" then
					aip.run.pin("workbench-legacy-sub-agent", 1, {
						label = CONST.LABEL_WORKBENCH,
						content = "Legacy sub-agent name `pro@coder/dev` detected.\nNormalized to `pro@coder/workbench`."
					})
				end
				if workbench_config.enabled == nil then
					workbench_config.enabled = true
				end
				if workbench_config.on == nil then
					workbench_config.on = "start"
				end
				return workbench_config
			end
		end
		return item
	end
end

local function normalize_sub_agent_events(config)
	if type(config) ~= "table" then return nil end

	local on = config.on
	if on == nil then
		on = { "start" }
	end

	if type(on) == "string" then
		config.on = { on }
	elseif type(on) == "table" then
		local normalized = {}
		for _, event_name in ipairs(on) do
			if type(event_name) == "string" and event_name ~= "" then
				table.insert(normalized, event_name)
			end
		end
		if #normalized == 0 then
			normalized = { "start" }
		end
		config.on = normalized
	else
		config.on = { "start" }
	end

	return config
end

local function config_matches_event(config, event_name)
	if type(config) ~= "table" or config.enabled == false then
		return false
	end

	local events = config.on
	if type(events) == "string" then
		return events == event_name
	end

	if type(events) ~= "table" then
		return event_name == "start"
	end

	for _, current_event in ipairs(events) do
		if current_event == event_name then
			return true
		end
	end

	return false
end

local function extract_sub_agent_configs(sub_agents, options)
	local configs = {}
	if type(sub_agents) ~= "table" then return configs end

	for _, item in ipairs(sub_agents) do
		local sub_agent_config = new_sub_agent_config(item, options)
		if sub_agent_config then
			normalize_sub_agent_events(sub_agent_config)
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

local function clone_agent_configs(configs)
	local cloned = {}
	if type(configs) ~= "table" then
		return cloned
	end

	for _, config in ipairs(configs) do
		table.insert(cloned, clone_shallow(config))
	end

	return cloned
end

local function normalize_emit_events(emit_events)
	if type(emit_events) ~= "table" then
		return nil
	end

	local normalized = {}
	for _, event_name in ipairs(emit_events) do
		if type(event_name) == "string" and event_name ~= "" then
			table.insert(normalized, event_name)
		end
	end

	if #normalized == 0 then
		return nil
	end

	return normalized
end

local function new_dispatch_item(event_name, stage_name, agent_configs, history)
	return {
		event = event_name,
		stage = stage_name,
		agent_configs = clone_agent_configs(agent_configs),
		history = clone_history(history or {}),
	}
end

local function new_workbench_sub_agent_config(workbench, options)
	return u_workbench.new_workbench_sub_agent_config(workbench, options)
end

local function extract_coder_params(coder_meta)
	local params = {}
	aip.lua.merge_deep(params, coder_meta)
	params.sub_agents = nil
	params.workbench = nil
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

local function run_sub_agents_dispatch(dispatch_item, coder_meta, inst, coder_options, coder_prompt_dir)
	local agent_configs = extract_sub_agent_configs(coder_meta.sub_agents, { coder_prompt_dir = coder_prompt_dir })
	if #agent_configs == 0 then
		return coder_meta, inst
	end

	local current_params = aip.lua.merge_deep({}, coder_meta)
	current_params.sub_agents = nil -- for now remove this list (we might put the agent_configs later)

	-- Ensure glob parameters are tables if nil
	current_params.context_globs = value_or(current_params.context_globs, {})
	current_params.structure_globs = value_or(current_params.structure_globs, {})
	current_params.knowledge_globs = value_or(current_params.knowledge_globs, {})
	current_params.context_globs_pre = value_or(current_params.context_globs_pre, {})
	current_params.context_globs_post = value_or(current_params.context_globs_post, {})
	current_params.knowledge_globs_pre = value_or(current_params.knowledge_globs_pre, {})
	current_params.knowledge_globs_post = value_or(current_params.knowledge_globs_post, {})

	local current_coder_prompt = inst
	local extra_sub_input = coder_options and coder_options.extra_sub_input or nil
	local coder_workbench = coder_options and coder_options.coder_workbench or nil
	local event_queue = {
		new_dispatch_item(dispatch_item.event, dispatch_item.stage, agent_configs, dispatch_item.history or {})
	}

	local steps = 0

	while #event_queue > 0 do
		steps = steps + 1
		if steps > MAX_SUB_AGENT_STEPS then
			return nil, nil, "Sub-agent pipeline exceeded max steps (" .. MAX_SUB_AGENT_STEPS .. ")."
		end

		local dispatch = table.remove(event_queue, 1)
		local dispatch_event = dispatch.event
		local dispatch_stage = dispatch.stage
		local dispatch_agent_configs = dispatch.agent_configs
		local executed = dispatch.history or {}
		local subscriber_configs = clone_agent_configs(dispatch_agent_configs)
		local i = 1

		while i <= #subscriber_configs do
			local config = subscriber_configs[i]
			if config_matches_event(config, dispatch_event) then
				local sub_agents_prev = clone_history(executed)
				local sub_agents_next = {}
				for j = i + 1, #subscriber_configs do
					table.insert(sub_agents_next, clone_shallow(subscriber_configs[j]))
				end

				local err
				local returned_next
				local agent_result
				local emit_events
				current_params, current_coder_prompt, returned_next, agent_result, emit_events, err = run_sub_agent(
					config,
					dispatch_stage,
					current_params,
					current_coder_prompt,
					aip.lua.merge_deep({}, coder_options, {
						event = dispatch_event,
						sub_agents_prev = sub_agents_prev,
						sub_agents_next = sub_agents_next,
						coder_workbench = coder_workbench,
						extra_sub_input = extra_sub_input
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
						table.insert(rebuilt, subscriber_configs[k])
					end
					for _, cfg in ipairs(returned_next) do
						table.insert(rebuilt, cfg)
					end
					subscriber_configs = rebuilt
				end

				if emit_events ~= nil then
					for _, emitted_event in ipairs(emit_events) do
						table.insert(event_queue, new_dispatch_item(emitted_event, dispatch_stage, subscriber_configs, executed))
					end
				end
			end

			i = i + 1
		end

		agent_configs = subscriber_configs
	end

	local new_coder_meta = current_params
	-- put back the sub_agents
	new_coder_meta.sub_agents = agent_configs

	return new_coder_meta, current_coder_prompt
end

-- === /Support Functions

-- === Public Interfaces

-- Runs a single sub-agent.
-- Returns modified params, modified prompt, and error message if any.
function run_sub_agent(config, stage, current_params, current_coder_prompt, coder_options, coder_prompt_dir)
	local opts = coder_options or {}
	local sub_agents_prev = opts.sub_agents_prev
	local sub_agents_next = opts.sub_agents_next
	local extra_sub_input = opts.extra_sub_input
	local coder_workbench = opts.coder_workbench
	local event_name = opts.event
	opts.sub_agents_prev = nil
	opts.sub_agents_next = nil
	opts.extra_sub_input = nil
	opts.coder_workbench = nil
	opts.event = nil

	if config.enabled == false then
		return current_params, current_coder_prompt, nil, nil, nil
	end

	local coder_params_for_sub = extract_coder_params(current_params)
	local sub_input = {
		_display         =
		"sub agent input {event, stage, coder_stage, coder_params, coder_workbench, coder_prompt, agent_config, coder_prompt_dir, sub_agents_prev, sub_agents_next}",
		event            = event_name,
		stage            = stage,
		coder_params     = coder_params_for_sub,
		coder_workbench  = coder_workbench,
		coder_prompt     = current_coder_prompt,
		coder_prompt_dir = coder_prompt_dir,
		agent_config     = config,
		sub_agents_prev  = sub_agents_prev,
		sub_agents_next  = sub_agents_next,
	}
	if type(extra_sub_input) == "table" then
		sub_input = aip.lua.merge(sub_input, extra_sub_input)
	end

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
	local emit_events = nil

	-- If res is nil, it is considered success with no modifications to the state.
	if res == nil then return current_params, current_coder_prompt, next_configs, nil, emit_events end

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

	emit_events = normalize_emit_events(res.emit_events)
	local agent_result = type(res) == "table" and res.agent_result or nil

	return current_params, current_coder_prompt, next_configs, agent_result, emit_events
end

-- Executes pre-stage sub-agents with the explicit root start event.
-- Returns the modified meta and instruction string (derived from concatenated prompts).
function run_sub_agents_pre(coder_meta, inst, coder_options, coder_prompt_dir)
	-- Check AIPack version for sub-agent support
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.14") then
		return nil, nil, "Sub-agents require AIPack 0.8.15 or above (current: " .. CTX.AIPACK_VERSION .. ")"
	end

	return run_sub_agents_dispatch({
		event = "start",
		stage = "pre",
		history = {},
	}, coder_meta, inst, coder_options, coder_prompt_dir)
end

-- Executes post-stage sub-agents with the explicit root end event.
-- Returns the modified meta and instruction string (derived from concatenated prompts).
function run_sub_agents_post(coder_meta, inst, coder_options, coder_prompt_dir)
	-- Check AIPack version for sub-agent support
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.14") then
		return nil, nil, "Sub-agents require AIPack 0.8.15 or above (current: " .. CTX.AIPACK_VERSION .. ")"
	end

	return run_sub_agents_dispatch({
		event = "end",
		stage = "post",
		history = {},
	}, coder_meta, inst, coder_options, coder_prompt_dir)
end

-- === /Public Interfaces

return {
	config_matches_event       = config_matches_event,
	new_workbench_sub_agent_config = new_workbench_sub_agent_config,
	new_dev_sub_agent_config   = new_workbench_sub_agent_config,
	normalize_sub_agent_events = normalize_sub_agent_events,
	run_sub_agent              = run_sub_agent,
	run_sub_agents_post        = run_sub_agents_post,
	run_sub_agents_pre         = run_sub_agents_pre
}
