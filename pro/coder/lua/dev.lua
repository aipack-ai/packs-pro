local function resolve_dev_chat_path(dev_chat_path, options)
	options = options or {}
	local coder_prompt_dir = options.coder_prompt_dir or "."

	if is_null(dev_chat_path) or dev_chat_path == "" then
		return coder_prompt_dir .. "/dev/chat/dev-chat.md"
	end

	return dev_chat_path
end

local function normalize_dev_chat_config(dev_chat, options)
	local chat = nil
	if dev_chat == true then
		chat = {
			enabled = true,
			path = resolve_dev_chat_path(nil, options)
		}
	elseif type(dev_chat) == "string" then
		chat = {
			enabled = true,
			path = resolve_dev_chat_path(dev_chat, options)
		}
	elseif type(dev_chat) == "table" then
		chat = aip.lua.merge({ enabled = true }, dev_chat)
		chat.path = resolve_dev_chat_path(chat.path, options)
	end
	return chat
end

local function new_dev_sub_agent_config(dev, options)
	local dev_config = nil

	if dev == true then
		dev_config = {
			name = "pro@coder/dev",
			enabled = true,
			chat = normalize_dev_chat_config(true, options)
		}
	elseif type(dev) == "table" then
		local base = aip.lua.merge({ name = "pro@coder/dev", enabled = true }, dev)
		base.chat = normalize_dev_chat_config(base.chat, options)
		dev_config = base
	end

	return dev_config
end

return {
	new_dev_sub_agent_config = new_dev_sub_agent_config,
	normalize_dev_chat_config = normalize_dev_chat_config,
	resolve_dev_chat_path = resolve_dev_chat_path
}
