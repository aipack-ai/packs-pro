--
local _cm = require("code_map")

-- CONSTS
local LABEL_STATUS = "       Status:"
local LABEL_CFILES = "Context Files:"
local LABEL_REASON = "       Reason:"
local LABEL_HFILES = " Helper Files:"

local DEFAULT_INPUT_CONCURRENCY = 8


-- return: {
--  user_prompt: string,
--  mode: "reduce" | "expand",
--  model: string,
--  helper_globs?: string[],
--  code_map_globs: string[],
--  code_map_model: string,
--  code_map_input_concurrency: number,
-- }
local function extract_auto_context_config(sub_input)
	-- input_agent_config
	local input_agent_config = sub_input.agent_config

	-- user_prompt
	local user_prompt = sub_input.coder_prompt

	-- helper_globs
	local helper_globs = input_agent_config.helper_globs

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
	-- if still nil, will default to the default of code-map

	return {
		user_prompt                = user_prompt,
		mode                       = mode,
		model                      = model,
		helper_globs               = helper_globs,
		code_map_globs             = code_map_globs,
		code_map_model             = code_map_model,
		code_map_input_concurrency = code_map_input_concurrency,
		map_name                   = input_agent_config.map_name or "context"
	}
end

-- ctx: {
--    context_files_count: number,
--    context_files_size: number,
--    new_context_globs?: string[],
--    reason?: string,
--    helper_files?: string[]
-- }
local function pin_status(auto_context_config, ctx)
	local mode = auto_context_config.mode
	local done = false
	if ctx.new_context_globs then
		done = true
	end

	local new_context_files = nil
	local new_context_files_size = nil
	if ctx.new_context_globs then
		new_context_files_size = 0
		new_context_files = aip.file.list(ctx.new_context_globs)
		for _, file in ipairs(new_context_files) do
			new_context_files_size = new_context_files_size + file.size
		end
	end


	-- === Status pin
	local context_files_size_fmt = aip.text.format_size(ctx.context_files_size)
	local msg = nil
	if done then
		msg = "✅"
	else
		msg = ".."
	end
	local label = nil
	if mode == "expand" then
		label = " Expanding"
	else
		label = " Reducing"
	end

	msg = msg .. string.format("%-30s", label .. " " .. ctx.context_files_count .. " context files")
	msg = msg .. " (" .. context_files_size_fmt .. ")"

	if ctx.new_context_globs then
		msg = msg .. '\n' .. " ➜"
		msg = msg .. string.format("%-30s", " Now " .. #new_context_files .. " context files")
		local new_context_files_size_fmt = aip.text.format_size(new_context_files_size)
		msg = msg .. " (" .. new_context_files_size_fmt .. ")"
	end

	-- Pins for status
	local status_pin = {
		label = LABEL_STATUS,
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
			msg = aip.text.trim_end(msg) -- poor man
		end
		-- files it in both
		local files_pin = {
			label = LABEL_CFILES,
			content = msg
		}
		aip.run.pin("files", 2, files_pin)
		aip.task.pin("files", 2, files_pin)
	end

	-- === Pin Reason
	if ctx.reason then
		local reason_pin = {
			label = LABEL_REASON,
			content = aip.text.trim(ctx.reason)
		}
		aip.run.pin("reason", 3, reason_pin)
		aip.task.pin("reason", 3, reason_pin)
	end

	-- === Helper  helper_files
	if ctx.helper_files then
		local content = ""
		for _, file in ipairs(ctx.helper_files) do
			content = content .. "- " .. file.path .. "\n"
		end
		content = aip.text.trim_end(content) -- poor man
		local helpers_pin = {
			label = LABEL_HFILES,
			content = content
		}
		aip.run.pin("helpers", 4, helpers_pin)
		aip.task.pin("helpers", 4, helpers_pin)
	end
end


return {
	extract_auto_context_config = extract_auto_context_config,
	pin_status                  = pin_status,
}
