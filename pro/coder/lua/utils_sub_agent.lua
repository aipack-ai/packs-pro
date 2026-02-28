-- === Support Functions

local function extract_sub_agent_configs(sub_agents)
	local configs = {}
	if type(sub_agents) ~= "table" then return configs end
	for _, item in ipairs(sub_agents) do
		if type(item) == "string" then
			table.insert(configs, { name = item })
		elseif type(item) == "table" and item.name then
			table.insert(configs, item)
		end
	end
	return configs
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

-- === /Support Functions

-- === Public Interfaces

-- Executes a list of sub-agents for a specific stage.
-- Returns the modified meta and instruction string (derived from concatenated prompts).
function run_sub_agents(stage, coder_meta, inst, coder_options, coder_prompt_dir)
	-- Check AIPack version for sub-agent support
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.14") then
		return nil, nil, "Sub-agents require AIPack 0.8.15 or above (current: " .. CTX.AIPACK_VERSION .. ")"
	end

	local sub_agents = coder_meta.sub_agents

	local agent_configs = extract_sub_agent_configs(sub_agents)
	if #agent_configs == 0 then
		return coder_meta, inst
	end

	local current_params = coder_meta
	current_params.sub_agents = nil -- for now remove this list (we might put the agent_configs later)

	-- Ensure glob parameters are tables if nil
	current_params.context_globs = value_or(current_params.context_globs, {})
	current_params.structure_globs = value_or(current_params.structure_globs, {})
	current_params.knowledge_globs = value_or(current_params.knowledge_globs, {})

	local current_coder_prompt = inst

	for _, config in ipairs(agent_configs) do
		local coder_params_for_sub = extract_coder_params(current_params)
		local sub_input = {
			_display         = "sub agent input {coder_stage, coder_params, coder_prompt, agent_config, coder_prompt_dir}",
			coder_stage      = stage,
			coder_params     = coder_params_for_sub,
			coder_prompt     = current_coder_prompt,
			coder_prompt_dir = coder_prompt_dir,
			agent_config     = config,
		}

		-- would be nil if no config.options, which is fine
		local config_options = aip.agent.extract_options(config.options)
		local options = aip.lua.merge_deep({}, coder_options, config_options)

		-- Run the agent with a single input in the list
		local run_res = aip.agent.run(config.name, {
			input = sub_input,
			options = options,
			agent_base_dir = CTX.WORKSPACE_DIR
		})

		if run_res == nil then
			return nil, nil, "Sub-agent [" .. config.name .. "] execution failed (no response)"
		end

		local res = extract_sub_agent_response(run_res)

		-- If res is nil, it is considered success with no modifications to the state.
		if res == nil then goto next_agent end

		-- Validate the response structure
		if type(res) == "table" then
			-- If success is false or error_msg is present, we stop execution
			if res.success == false or res.error_msg ~= nil then
				local err_msg = value_or(res.error_msg, "Unknown error")
				local full_err = "Sub-agent [" .. config.name .. "] failed: " .. err_msg
				if res.error_details then
					full_err = full_err .. "\nDetails: " .. res.error_details
				end
				return nil, nil, full_err
			end

			-- Merge or replace state
			if res.coder_params then
				-- we merge here so, that the return value does not have to return unchanged things
				current_params = aip.lua.merge(current_params, res.coder_params)
			end
			if res.coder_prompt then
				current_coder_prompt = res.coder_prompt
			end
		else
			-- Note: for now, do not return error
			-- return nil, nil, "Sub-agent [" .. config.name .. "] returned an invalid response format ( not a table)"
		end

		::next_agent::
	end

	local new_coder_meta = current_params
	-- put back the sub_agents
	new_coder_meta.sub_agents = sub_agents

	return new_coder_meta, current_coder_prompt
end

-- === /Public Interfaces

return {
	run_sub_agents = run_sub_agents
}
