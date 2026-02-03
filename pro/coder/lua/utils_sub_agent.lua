-- === Support Functions

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
function run_sub_agents(stage, coder_meta, inst)
	local sub_agents = coder_meta.sub_agents
	if not sub_agents or #sub_agents == 0 then
		return coder_meta, inst
	end

	-- Check AIPack version for sub-agent support
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.14") then
		return nil, nil, "Sub-agents require AIPack 0.8.15 or above (current: " .. CTX.AIPACK_VERSION .. ")"
	end

	local current_params = coder_meta

	local current_coder_prompts = { inst }

	for _, agent_name in ipairs(sub_agents) do
		local sub_input = {
			_display      = "sub agent input {coder_stage, coder_params, coder_prompts}",
			coder_stage   = stage,
			coder_params  = current_params,
			coder_prompts = current_coder_prompts,
		}

		-- Run the agent with a single input in the list
		local run_res = aip.agent.run(agent_name, {
			input = sub_input,
			agent_base_dir = CTX.WORKSPACE_DIR
		})

		if run_res == nil then
			return nil, nil, "Sub-agent [" .. agent_name .. "] execution failed (no response)"
		end

		local res = extract_sub_agent_response(run_res)

		-- If res is nil, it is considered success with no modifications to the state.
		if res == nil then goto next_agent end

		-- Validate the response structure
		if type(res) ~= "table" then
			return nil, nil, "Sub-agent [" .. agent_name .. "] returned an invalid response format ()"
		end

		if res.success == false then
			local err_msg = res.error_msg or "Unknown error"
			local full_err = "Sub-agent [" .. agent_name .. "] failed: " .. err_msg
			if res.error_details then
				full_err = full_err .. "\nDetails: " .. res.error_details
			end
			return nil, nil, full_err
		end

		-- Merge or replace state
		if res.coder_params then
			current_params = res.coder_params
		end
		if res.coder_prompts then
			current_coder_prompts = res.coder_prompts
		end
		::next_agent::
	end

	return current_params, table.concat(current_coder_prompts, "\n\n")
end

-- === /Public Interfaces

return {
	run_sub_agents = run_sub_agents
}
