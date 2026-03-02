--
local _cm                       = require("code_map")

-- CONSTS
local LABEL_STATUS              = "          Status:"
local LABEL_CFILES              = "   Context Files:"
local LABEL_REASON              = "  Context Reason:"
local LABEL_KFILES              = " Knowledge Files:"
local LABEL_KREASON             = "Knowledge Reason:"
local LABEL_HFILES              = "    Helper Files:"

local DEFAULT_INPUT_CONCURRENCY = 8


-- return: {
--  user_prompt: string,
--  mode: "reduce" | "expand",
--  model: string,
--  helper_globs?: string[],
--  code_map_globs: string[],
--  code_map_model: string,
--  code_map_input_concurrency: number,
--  knowledge: boolean,
--  knowledge_globs?: string[],
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

	-- knowledge
	local knowledge = input_agent_config.knowledge or false
	local knowledge_globs = nil
	if knowledge then
		knowledge_globs = sub_input.coder_params.knowledge_globs
		-- If knowledge is true but no knowledge_globs, silently skip
		if not knowledge_globs or #knowledge_globs == 0 then
			knowledge = false
			knowledge_globs = nil
		end
	end

	return {
		user_prompt                = user_prompt,
		mode                       = mode,
		model                      = model,
		helper_globs               = helper_globs,
		code_map_globs             = code_map_globs,
		code_map_model             = code_map_model,
		code_map_input_concurrency = code_map_input_concurrency,
		map_name                   = input_agent_config.map_name or "context",
		knowledge                  = knowledge,
		knowledge_globs            = knowledge_globs,
	}
end

-- ctx: {
--    context_files_count: number,
--    context_files_size: number,
--    new_context_globs?: string[],
--    reason?: string,
--    helper_files?: string[],
--    knowledge_files_count?: number,
--    knowledge_files_size?: number,
--    new_knowledge_globs?: string[],
--    knowledge_reason?: string,
-- }
local function pin_status(auto_context_config, ctx)
	local mode = auto_context_config.mode
	local done = false
	if ctx.new_context_globs then
		done = true
	end
	-- For knowledge, done when new_knowledge_globs is set (or knowledge not enabled)
	local knowledge_done = false
	if not auto_context_config.knowledge then
		knowledge_done = true
	elseif ctx.new_knowledge_globs then
		knowledge_done = true
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

	local new_knowledge_files = nil
	local new_knowledge_files_size = nil
	if ctx.new_knowledge_globs then
		new_knowledge_files_size = 0
		new_knowledge_files = aip.file.list(ctx.new_knowledge_globs)
		for _, file in ipairs(new_knowledge_files) do
			new_knowledge_files_size = new_knowledge_files_size + file.size
		end
	end

	-- === Status pin
	local context_files_size_fmt = aip.text.format_size(ctx.context_files_size)
	local msg = nil
	if done and knowledge_done then
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

	-- Knowledge status line
	if auto_context_config.knowledge then
		local knowledge_files_size_fmt = aip.text.format_size(ctx.knowledge_files_size or 0)
		msg = msg .. '\n' .. "  "
		msg = msg .. string.format("%-30s", " Reducing " .. (ctx.knowledge_files_count or 0) .. " knowledge files")
		msg = msg .. " (" .. knowledge_files_size_fmt .. ")"

		if ctx.new_knowledge_globs then
			msg = msg .. '\n' .. " ➜"
			msg = msg .. string.format("%-30s", " Now " .. #new_knowledge_files .. " knowledge files")
			local new_knowledge_files_size_fmt = aip.text.format_size(new_knowledge_files_size)
			msg = msg .. " (" .. new_knowledge_files_size_fmt .. ")"
		end
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

	-- === Pin Knowledge Files
	if knowledge_done and auto_context_config.knowledge and new_knowledge_files then
		msg = ""
		for _, file in ipairs(new_knowledge_files) do
			msg = msg .. "  - " .. file.path .. "\n"
		end
		msg = aip.text.trim_end(msg)
		local kfiles_pin = {
			label = LABEL_KFILES,
			content = msg
		}
		aip.run.pin("kfiles", 5, kfiles_pin)
		aip.task.pin("kfiles", 5, kfiles_pin)
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

	-- === Pin Knowledge Reason
	if ctx.knowledge_reason then
		local kreason_pin = {
			label = LABEL_KREASON,
			content = aip.text.trim(ctx.knowledge_reason)
		}
		aip.run.pin("kreason", 6, kreason_pin)
		aip.task.pin("kreason", 6, kreason_pin)
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
