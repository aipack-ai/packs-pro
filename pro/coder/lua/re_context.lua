--
local _cm = require("code_map")

-- return: {
--  user_prompt: string,
--  mode: "reduce" | "expand",
--  model: string,
--  code_map_globs: string[],
--  code_map_model: string,
--  code_map_input_concurrency: number,
-- }
local function extract_re_context_config(sub_input)
	-- input_agent_config
	local input_agent_config = sub_input.agent_config

	-- user_prompt
	local user_prompt = sub_input.coder_prompt

	-- mode
	local mode = sub_input.agent_config.mode
	if not mode then
		mode = "reduce"
	end
	if not (mode == "reduce" or mode == "expand") then
		error("mode '" .. mode .. "' not valid. Can only be 'reduce' (default) or 'expand'")
	end

	-- model
	local model = input_agent_config.model
	if not model then
		model = sub_input.coder_params.model
	end

	-- code_map_globs
	local code_map_globs = sub_input.coder_params.context_globs -- default for reduce
	if mode == "expand" then
		code_map_globs = sub_input.coder_params.structure_globs
	end

	-- code_map_model
	local code_map_model = input_agent_config.code_map_model
	if not code_map_model then
		code_map_model = model -- the model resolved above (same as re-context)
	end

	-- code_map_input_concurrency
	local code_map_input_concurrency = input_agent_config.code_map_input_concurrency
	if not code_map_input_concurrency then
		code_map_input_concurrency = input_agent_config.input_concurrency
	end
	if not code_map_input_concurrency then
		code_map_input_concurrency = sub_input.coder_params.input_concurrency
	end

	return {
		user_prompt                = user_prompt,
		mode                       = mode,
		model                      = model,
		code_map_globs             = code_map_globs,
		code_map_model             = code_map_model,
		code_map_input_concurrency = code_map_input_concurrency
	}
end

-- ctx: {
--    context_files_count: number,
--    new_context_globs: string[],
-- }
local function pin_status(re_context_config, ctx)
	local mode = re_context_config.mode
	local done = false
	if ctx.new_context_globs then
		done = true
	end

	local new_context_files = nil

	if ctx.new_context_globs then
		new_context_files = aip.file.list(ctx.new_context_globs)
	end

	-- === Status pin
	local msg = nil
	if done then
		msg = "✅"
	else
		msg = ".."
	end
	if mode == "expand" then
		msg = msg .. " Expanding"
	else
		msg = msg .. " Reducing"
	end

	msg = msg .. " " .. ctx.context_files_count .. " context files"

	if ctx.new_context_globs then
		msg = msg .. '\n' .. " ➜ Now " .. #new_context_files .. " context files"
	end

	-- Pins for statu
	local status_pin = {
		label = "       Status:",
		content = msg
	}
	aip.run.pin("status", 1, status_pin)
	aip.task.pin("status", 1, status_pin)

	-- === Pin Context Files
	if done then
		msg = ""
		if new_context_files then
			for _, file in ipairs(new_context_files) do
				msg = msg .. "  - " .. file.path .. "\n"
			end
		end
		-- files it in both
		local files_pin = {
			label = "Context Files:",
			content = msg
		}
		aip.run.pin("files", 2, files_pin)
		aip.task.pin("files", 2, files_pin)
	end
end


return {
	extract_re_context_config = extract_re_context_config,
	pin_status                = pin_status
}
