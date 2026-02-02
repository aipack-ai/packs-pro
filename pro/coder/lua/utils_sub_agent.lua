local M = {}

-- Executes a list of sub-agents for a specific stage.
-- Returns the modified meta and instruction string (derived from concatenated prompts).
function M.run_sub_agents(stage, meta, inst)
	local sub_agents = meta.sub_agents
	if not sub_agents or #sub_agents == 0 then
		return meta, inst
	end

	local current_meta = meta
	local current_prompts = { inst }

	for _, agent_name in ipairs(sub_agents) do
		local sub_input = {
			coder_stage = stage,
			meta        = current_meta,
			prompts     = current_prompts
		}

		-- Run the agent with a single input in the list
		local run_res = aip.agent.run(agent_name, { inputs = { sub_input } })

		if not run_res then
			return nil, nil, "Sub-agent [" .. agent_name .. "] execution failed (no response)"
		end

		local res = run_res.after_all

		-- If res is nil, it is considered success with no modifications to the state.
		if res == nil then goto next_agent end

		-- Validate the response structure
		if type(res) ~= "table" or res.success == nil then
			return nil, nil, "Sub-agent [" .. agent_name .. "] returned an invalid response format (missing success flag)"
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
		if res.meta then
			current_meta = res.meta
		end
		if res.prompts then
			current_prompts = res.prompts
		end
		::next_agent::
	end

	return current_meta, table.concat(current_prompts, "\n\n")
end

return M
