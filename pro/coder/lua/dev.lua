local u_common = require("utils_common")

local function resolve_dev_chat_path(dev_chat_path, options)
	return u_common.resolve_dev_chat_path(dev_chat_path, options)
end

local function resolve_dev_plan_dir(dev_plan_dir, options)
	options = options or {}
	return u_common.resolve_dev_plan_dir(dev_plan_dir, options)
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

local function normalize_dev_plan_config(dev_plan, options)
	local plan = nil
	if dev_plan == true then
		plan = {
			enabled = true,
			dir = resolve_dev_plan_dir(nil, options)
		}
	elseif type(dev_plan) == "string" then
		plan = {
			enabled = true,
			dir = resolve_dev_plan_dir(dev_plan, options)
		}
	elseif type(dev_plan) == "table" then
		plan = aip.lua.merge({ enabled = true }, dev_plan)
		plan.dir, plan._resolve_err = resolve_dev_plan_dir(plan.dir, aip.lua.merge({}, options, { strict_dir = true }))
	end
	return plan
end

local function normalize_dev_spec_config(dev_spec, options)
	local spec = nil
	if dev_spec == true then
		spec = {
			enabled = true,
			path = u_common.resolve_dev_spec_path(nil, options)
		}
	elseif type(dev_spec) == "string" then
		spec = {
			enabled = true,
			path = u_common.resolve_dev_spec_path(dev_spec, options)
		}
	elseif type(dev_spec) == "table" then
		spec = aip.lua.merge({ enabled = true }, dev_spec)
		spec.path = u_common.resolve_dev_spec_path(spec.path, options)
	end
	return spec
end

local function new_dev_sub_agent_config(dev, options)
	local dev_config = nil

	if is_null(dev) then
		dev_config = {
			name = "pro@coder/dev",
			enabled = false
		}
	elseif dev == true then
		dev_config = {
			name = "pro@coder/dev",
			enabled = true
		}
	elseif dev == false then
		dev_config = {
			name = "pro@coder/dev",
			enabled = false
		}
	elseif type(dev) == "table" then
		local base = aip.lua.merge({ name = "pro@coder/dev", enabled = true }, dev)
		base.chat = normalize_dev_chat_config(base.chat, options)
		base.plan = normalize_dev_plan_config(base.plan, options)
		base.spec = normalize_dev_spec_config(base.spec, options)
		local chat_enabled = not is_null(base.chat) and base.chat.enabled ~= false
		local plan_enabled = not is_null(base.plan) and base.plan.enabled ~= false
		local spec_enabled = not is_null(base.spec) and base.spec.enabled ~= false
		if not chat_enabled and not plan_enabled and not spec_enabled then
			base.enabled = false
		end
		dev_config = base
	end

	return dev_config
end

return {
	new_dev_sub_agent_config = new_dev_sub_agent_config,
	normalize_dev_chat_config = normalize_dev_chat_config,
	resolve_dev_chat_path = resolve_dev_chat_path,
	normalize_dev_plan_config = normalize_dev_plan_config,
	resolve_dev_plan_dir = resolve_dev_plan_dir,
	normalize_dev_spec_config = normalize_dev_spec_config
}
