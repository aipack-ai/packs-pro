local function resolve_dev_chat_path(dev_chat_path, options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."

	if is_null(dev_chat_path) or dev_chat_path == "" then
		return coder_prompt_dir .. "/dev/chat/dev-chat.md"
	end

	return dev_chat_path
end

local function new_dev_chat_sub_agent_config(dev_chat, options)
	local dc_config = nil
	if dev_chat == true then
		dc_config = {
			name = "pro@coder/dev-chat",
			enabled = true,
			path = resolve_dev_chat_path(nil, options)
		}
	elseif type(dev_chat) == "string" then
		dc_config = {
			name = "pro@coder/dev-chat",
			enabled = true,
			path = resolve_dev_chat_path(dev_chat, options)
		}
	elseif type(dev_chat) == "table" then
		dc_config = aip.lua.merge({ name = "pro@coder/dev-chat", enabled = true }, dev_chat)
		dc_config.path = resolve_dev_chat_path(dc_config.path, options)
	end
	return dc_config
end

return {
	new_dev_chat_sub_agent_config = new_dev_chat_sub_agent_config,
	resolve_dev_chat_path = resolve_dev_chat_path
}
