local u_common = require("utils_common")

local function resolve_workbench_chat_path(workbench_chat_path, options)
	return u_common.resolve_workbench_chat_path(workbench_chat_path, options)
end

local function resolve_workbench_plan_dir(workbench_plan_dir, options)
	options = options or {}
	return u_common.resolve_workbench_plan_dir(workbench_plan_dir, options)
end

local function normalize_workbench_dir(workbench_dir)
	if type(workbench_dir) ~= "string" then
		return nil
	end
	local normalized = workbench_dir:gsub("/+$", "")
	if normalized == "" then
		return nil
	end
	return normalized
end

local function normalize_workbench_chat_config(workbench_chat, options)
	local chat = nil
	if workbench_chat == true then
		chat = {
			enabled = true,
			path = resolve_workbench_chat_path(nil, options)
		}
	elseif type(workbench_chat) == "string" then
		chat = {
			enabled = true,
			path = resolve_workbench_chat_path(workbench_chat, options)
		}
	elseif type(workbench_chat) == "table" then
		chat = aip.lua.merge({ enabled = true }, workbench_chat)
		chat.path = resolve_workbench_chat_path(chat.path, options)
	end
	return chat
end

local function normalize_workbench_plan_config(workbench_plan, options)
	local plan = nil
	if workbench_plan == true then
		local dir, _rules_path, path = u_common.resolve_workbench_plan_paths(nil, options)
		plan = {
			enabled = true,
			dir = dir,
			path = path
		}
	elseif type(workbench_plan) == "string" then
		local dir, _rules_path, path = u_common.resolve_workbench_plan_paths(workbench_plan, options)
		plan = {
			enabled = true,
			dir = dir,
			path = path
		}
	elseif type(workbench_plan) == "table" then
		plan = aip.lua.merge({ enabled = true }, workbench_plan)
		local plan_value = plan.path
		if is_null(plan_value) or plan_value == "" then
			plan_value = plan.dir
		end
		plan.dir, _rules_path, plan.path = u_common.resolve_workbench_plan_paths(plan_value, options)
		if not is_null(plan.dir) and plan.dir ~= "" and plan.path ~= plan.dir .. "/plan.md" and not is_null(plan.dir) and plan.dir ~= "" then
			local resolved_parent = aip.path.parent(plan.path)
			if not is_null(resolved_parent) and resolved_parent ~= "" then
				plan.dir = resolved_parent
			end
		end
	end
	return plan
end

local function normalize_workbench_spec_config(workbench_spec, options)
	local spec = nil
	if workbench_spec == true then
		spec = {
			enabled = true,
			rules_path = u_common.resolve_workbench_spec_path(nil, options),
			path = select(2, u_common.resolve_workbench_spec_path(nil, options))
		}
	elseif type(workbench_spec) == "string" then
		local rules_path, spec_path = u_common.resolve_workbench_spec_path(workbench_spec, options)
		spec = {
			enabled = true,
			rules_path = rules_path,
			path = spec_path
		}
	elseif type(workbench_spec) == "table" then
		spec = aip.lua.merge({ enabled = true }, workbench_spec)
		spec.rules_path, spec.path = u_common.resolve_workbench_spec_path(spec.path, options)
	end
	return spec
end

local function new_workbench_sub_agent_config(workbench, options)
	local workbench_config = nil

	if is_null(workbench) then
		workbench_config = {
			name = "pro@coder/workbench",
			enabled = false
		}
	elseif workbench == true then
		workbench_config = {
			name = "pro@coder/workbench",
			enabled = true
		}
	elseif workbench == false then
		workbench_config = {
			name = "pro@coder/workbench",
			enabled = false
		}
	elseif type(workbench) == "table" then
		local base = aip.lua.merge({ name = "pro@coder/workbench", enabled = true }, workbench)
		base.dir = normalize_workbench_dir(base.dir)
		local resolve_options = aip.lua.merge({}, options, { workbench_dir = base.dir })
		base.chat = normalize_workbench_chat_config(base.chat, resolve_options)
		base.plan = normalize_workbench_plan_config(base.plan, resolve_options)
		base.spec = normalize_workbench_spec_config(base.spec, resolve_options)
		local chat_enabled = not is_null(base.chat) and base.chat.enabled ~= false
		local plan_enabled = not is_null(base.plan) and base.plan.enabled ~= false
		local spec_enabled = not is_null(base.spec) and base.spec.enabled ~= false
		if not chat_enabled and not plan_enabled and not spec_enabled then
			base.enabled = false
		end
		workbench_config = base
	end

	return workbench_config
end

return {
	new_workbench_sub_agent_config = new_workbench_sub_agent_config,
	normalize_workbench_chat_config = normalize_workbench_chat_config,
	resolve_workbench_chat_path = resolve_workbench_chat_path,
	normalize_workbench_plan_config = normalize_workbench_plan_config,
	resolve_workbench_plan_dir = resolve_workbench_plan_dir,
	normalize_workbench_spec_config = normalize_workbench_spec_config,
	new_dev_sub_agent_config = new_workbench_sub_agent_config,
	normalize_dev_chat_config = normalize_workbench_chat_config,
	resolve_dev_chat_path = resolve_workbench_chat_path,
	normalize_dev_plan_config = normalize_workbench_plan_config,
	resolve_dev_plan_dir = resolve_workbench_plan_dir,
	normalize_dev_spec_config = normalize_workbench_spec_config
}
