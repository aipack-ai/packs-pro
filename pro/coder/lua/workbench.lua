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
		local dir, rules_path, path = u_common.resolve_workbench_plan_paths(nil, options)
		plan = {
			enabled = true,
			dir = dir,
			path = path,
			rules_path = rules_path
		}
	elseif type(workbench_plan) == "string" then
		local dir, rules_path, path = u_common.resolve_workbench_plan_paths(workbench_plan, options)
		plan = {
			enabled = true,
			dir = dir,
			path = path,
			rules_path = rules_path
		}
	elseif type(workbench_plan) == "table" then
		plan = aip.lua.merge({ enabled = true }, workbench_plan)
		local plan_value = plan.path
		if is_null(plan_value) or plan_value == "" then
			plan_value = plan.dir
		end
		local rules_path
		plan.dir, rules_path, plan.path = u_common.resolve_workbench_plan_paths(plan_value, options)
		plan.rules_path = rules_path
		if not is_null(plan.dir) and plan.dir ~= "" and plan.path ~= plan.dir .. "/plan.md" then
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
		local rules_path, spec_path = u_common.resolve_workbench_spec_path(nil, options)
		spec = {
			enabled = true,
			rules_path = rules_path,
			path = spec_path,
			context_path = spec_path
		}
	elseif type(workbench_spec) == "string" then
		local rules_path, spec_path = u_common.resolve_workbench_spec_path(workbench_spec, options)
		spec = {
			enabled = true,
			rules_path = rules_path,
			path = spec_path,
			context_path = spec_path
		}
	elseif type(workbench_spec) == "table" then
		spec = aip.lua.merge({ enabled = true }, workbench_spec)
		spec.rules_path, spec.path = u_common.resolve_workbench_spec_path(spec.path, options)
		spec.context_path = spec.path
	end
	return spec
end

local function append_unique(list, value)
	for _, item in ipairs(list) do
		if item == value then
			return list
		end
	end
	table.insert(list, value)
	return list
end

local function collect_workbench_content_globs(coder_workbench)
	local globs = {}
	if is_null(coder_workbench) or type(coder_workbench) ~= "table" then
		return globs
	end

	local chat_path = coder_workbench.chat and coder_workbench.chat.path
	if not is_null(chat_path) and chat_path ~= "" then
		append_unique(globs, chat_path)
	end

	local plan_path = coder_workbench.plan and coder_workbench.plan.path
	if not is_null(plan_path) and plan_path ~= "" then
		append_unique(globs, plan_path)
	end

	local spec_path = coder_workbench.spec and (coder_workbench.spec.context_path or coder_workbench.spec.path)
	if not is_null(spec_path) and spec_path ~= "" then
		append_unique(globs, spec_path)
	end

	return globs
end

local function append_workbench_helper_globs(helper_globs, coder_workbench)
	local workbench_globs = collect_workbench_content_globs(coder_workbench)
	if #workbench_globs == 0 then
		return helper_globs
	end

	local next_helper_globs = helper_globs
	if type(next_helper_globs) ~= "table" then
		next_helper_globs = {}
	end

	for _, glob in ipairs(workbench_globs) do
		append_unique(next_helper_globs, glob)
	end

	return next_helper_globs
end

local function prepare_workbench(agent_config, coder_params, options)
	options = options or {}
	agent_config = agent_config or {}
	coder_params = coder_params or {}

	local chat = agent_config.chat
	if type(chat) ~= "table" then
		chat = nil
	elseif chat.enabled == false then
		chat = nil
	end

	local plan = agent_config.plan
	if type(plan) ~= "table" then
		plan = nil
	elseif plan.enabled == false then
		plan = nil
	elseif not is_null(plan._resolve_err) and plan._resolve_err ~= "" then
		aip.run.pin("workbench-plan", 3, {
			label = CONST.LABEL_PLAN,
			content = "ERROR: " .. plan._resolve_err
		})
		return {
			success = false,
			error_msg = plan._resolve_err
		}
	end

	local spec = agent_config.spec
	if type(spec) ~= "table" then
		spec = nil
	elseif spec.enabled == false then
		spec = nil
	end

	if chat == nil and plan == nil and spec == nil then
		return {
			coder_params = {}
		}
	end

	local next_context_globs_post = coder_params.context_globs_post
	if type(next_context_globs_post) ~= "table" then
		next_context_globs_post = {}
	end

	local next_knowledge_globs_pre = coder_params.knowledge_globs_pre
	if type(next_knowledge_globs_pre) ~= "table" then
		next_knowledge_globs_pre = {}
	end

	local next_knowledge_globs_post = coder_params.knowledge_globs_post
	if type(next_knowledge_globs_post) ~= "table" then
		next_knowledge_globs_post = {}
	end

	if chat ~= nil then
		local path, ensure_err = u_common.ensure_workbench_chat_file(chat.path, options)
		if is_null(path) or path == "" then
			return {
				success = false,
				error_msg = "Invalid workbench.chat.path"
			}
		end

		if ensure_err then
			return {
				success = false,
				error_msg = "Failed to initialize dev chat file",
				error_details = ensure_err
			}
		end

		chat.path = path
		append_unique(next_context_globs_post, path)
	end

	if plan ~= nil then
		local dir, _rules_path, plan_path, ensure_err = u_common.ensure_workbench_plan_file(plan.path or plan.dir, options)
		if ensure_err then
			aip.run.pin("workbench-plan", 3, {
				label = CONST.LABEL_PLAN,
				content = "ERROR: " .. ensure_err
			})
			return {
				success = false,
				error_msg = "Failed to initialize workbench plan rules file",
				error_details = ensure_err
			}
		end
		if is_null(dir) or dir == "" then
			return {
				success = false,
				error_msg = "Invalid workbench.plan.dir"
			}
		end
		plan.dir = dir
		plan.rules_path = _rules_path
		plan.path = plan_path

		append_unique(next_knowledge_globs_post, _rules_path)
		append_unique(next_context_globs_post, plan_path)
	end

	if spec ~= nil then
		local spec_rules_path, spec_context_path, spec_path, ensure_err = u_common.ensure_workbench_spec_file(spec.path, options)
		if ensure_err then
			aip.run.pin("workbench-spec", 4, {
				label = CONST.LABEL_SPEC,
				content = "ERROR: " .. ensure_err
			})
			return {
				success = false,
				error_msg = "Failed to initialize workbench spec rules file",
				error_details = ensure_err
			}
		end
		if is_null(spec_path) or spec_path == "" then
			return {
				success = false,
				error_msg = "Invalid workbench.spec.path"
			}
		end
		spec.rules_path = spec_rules_path
		spec.path = spec_path
		spec.context_path = spec_context_path

		append_unique(next_knowledge_globs_post, spec_rules_path)
		append_unique(next_context_globs_post, spec_context_path)
	end

	local updated_coder_params = {}
	if #next_context_globs_post > 0 then
		updated_coder_params.context_globs_post = next_context_globs_post
	end
	if #next_knowledge_globs_pre > 0 then
		updated_coder_params.knowledge_globs_pre = next_knowledge_globs_pre
	end
	if #next_knowledge_globs_post > 0 then
		updated_coder_params.knowledge_globs_post = next_knowledge_globs_post
	end

	local dev_content_globs = {}
	if chat ~= nil and not is_null(chat.path) and chat.path ~= "" then
		table.insert(dev_content_globs, chat.path)
	end
	if plan ~= nil and not is_null(plan.dir) and plan.dir ~= "" then
		table.insert(dev_content_globs, plan.path)
	end
	if spec ~= nil and not is_null(spec.context_path) and spec.context_path ~= "" then
		table.insert(dev_content_globs, spec.context_path)
	end

	return {
		coder_params = updated_coder_params,
		agent_result = {
			workbench_content_globs = dev_content_globs,
			dev_content_globs = dev_content_globs
		}
	}
end

local function clone_config_section(section)
	if is_null(section) or type(section) ~= "table" then
		return nil
	end
	return aip.lua.merge({}, section)
end

local function build_coder_workbench(workbench_config, options)
	options = options or {}
	if is_null(workbench_config) or type(workbench_config) ~= "table" or workbench_config.enabled == false then
		return nil
	end

	local prompt_cache_dir = options.prompt_cache_dir
	if is_null(prompt_cache_dir) or prompt_cache_dir == "" then
		local coder_prompt_dir = options.coder_prompt_dir
		if not is_null(coder_prompt_dir) and coder_prompt_dir ~= "" then
			prompt_cache_dir = coder_prompt_dir .. "/.cache"
		end
	end

	local dir = normalize_workbench_dir(workbench_config.dir)
	local cache_dir = prompt_cache_dir
	if not is_null(dir) and dir ~= "" then
		cache_dir = dir .. "/.cache"
	end

	return {
		dir = dir,
		cache_dir = cache_dir,
		prompt_cache_dir = prompt_cache_dir,
		chat = clone_config_section(workbench_config.chat),
		plan = clone_config_section(workbench_config.plan),
		spec = clone_config_section(workbench_config.spec)
	}
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
	build_coder_workbench = build_coder_workbench,
	prepare_workbench = prepare_workbench,
	normalize_workbench_chat_config = normalize_workbench_chat_config,
	resolve_workbench_chat_path = resolve_workbench_chat_path,
	collect_workbench_content_globs = collect_workbench_content_globs,
	append_workbench_helper_globs = append_workbench_helper_globs,
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
