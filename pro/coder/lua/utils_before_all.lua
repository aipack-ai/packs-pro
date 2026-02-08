-- CONST
local CONST = require("consts")

-- === Support Functions

-- Checks if the current AIPack version meets the minimum required version for this agent.
-- Returns true if OK, or false and an error message if an update is needed.
local function check_version()
	if not aip.semver.compare(CTX.AIPACK_VERSION, ">", "0.8.10") then
		local msg = "\nWARNING - This pack requires AIPACK_VERSION 0.8.4 or above, but " ..
				CTX.AIPACK_VERSION .. " is currently installed"
		msg = msg .. "\n\nACTION  - Update your aipack `cargo install aipack` (to check your aipack version run 'aip -V')"
		return false, msg
	end
	return true
end

-- Resolves various paths used by the agent based on the prompt file location.
-- Returns a table containing relative paths and absolute paths for cache files.
local function prepare_paths(prompt_file_path)
	local prompt_file_rel_path = nil
	if prompt_file_path:sub(1, 2) == "./" then
		prompt_file_rel_path = prompt_file_path:sub(3)
	else
		prompt_file_rel_path = aip.path.diff(prompt_file_path, CTX.WORKSPACE_DIR)
	end

	local prompt_dir = aip.path.parent(prompt_file_path)
	local cache_dir = prompt_dir .. "/.cache"

	return {
		prompt_file_rel_path               = prompt_file_rel_path,
		prompt_dir                         = prompt_dir,
		prompt_files_path                  = cache_dir .. "/last_prompt_files_path.md",
		ai_responses_for_raw_path          = cache_dir .. "/last_ai_responses_for_raw.md",
		ai_responses_for_prompt_path       = cache_dir .. "/last_ai_responses_for_prompt.md",
		last_file_change_fails_report_path = cache_dir .. "/last_file_change_fails_report.md"
	}
end

-- Cleans cache files.
local function clean_and_init_cache(paths)
	-- Clean legacy file (since 0.2.27)
	local legacy_prompt_files_path = paths.prompt_dir .. "/prompt_files_path.md"
	if aip.path.exists(legacy_prompt_files_path) then
		aip.file.delete(legacy_prompt_files_path)
	end

	-- Init cacche files
	aip.file.save(paths.prompt_files_path, "")
	aip.file.save(paths.ai_responses_for_raw_path, "")
	aip.file.save(paths.ai_responses_for_prompt_path, "")
	if aip.path.exists(paths.last_file_change_fails_report_path) then
		aip.file.delete(paths.last_file_change_fails_report_path)
	end
end

-- Prints summary information about the current run to the console.
local function print_run_info(input_base, working_refs_list, write_mode, input_concurrency)
	local context_file_count = input_base.context_refs and #input_base.context_refs or 0
	local context_file_count = tostring(context_file_count)
	local write_mode_fmt = tostring(write_mode)
	local working_group_count = working_refs_list and #working_refs_list or 0
	local knowledge_file_count = input_base.knowledge_refs and #input_base.knowledge_refs or 0
	local concurrency_fmt = "1"
	if working_refs_list and #working_refs_list > 0 then
		concurrency_fmt = tostring(input_concurrency)
	end

	local run_info = "Context Files: " .. context_file_count .. " | Working Groups: " ..
			working_group_count .. " | Knowledge Files: " .. knowledge_file_count
	run_info = run_info .. "\n(Write Mode: " .. write_mode_fmt .. ", Concurrency: " .. concurrency_fmt .. ")"
	print(run_info)
end

-- Splits the prompt Markdown content into instruction (first part) and previous content (second part).
-- It also cleans the second part by removing any existing note blocks (lines starting with '>').
local function extract_prompt_parts(prompt_content)
	local u_data = require("utils_data")
	-- Split the prompt into inst and content
	local first_part, second_part = u_data.prep_inst_and_content(prompt_content, "====", { content_is_default = false })

	-- Clean the second_part
	if second_part ~= nil then
		second_part = aip.text.trim(second_part)
		-- now remove the first line block with ">"
		local _note_blocks, remain = aip.text.extract_line_blocks(second_part,
			{ starts_with = ">", extrude = "content", first = 1 })
		second_part = aip.text.trim(remain)
		if #second_part == 0 then
			second_part = nil
		end
	end

	return first_part, second_part
end

-- Extracts TOML metadata and the Markdown instruction text from the first part of the prompt.
-- Returns a table for metadata and a string for the instruction.
local function extract_meta_and_inst(first_part)
	local meta, inst = aip.md.extract_meta(first_part)
	-- Remove the `> ..` lines
	local _line_blocks, inst_content = aip.text.extract_line_blocks(inst,
		{ starts_with = ">", extrude = "content" })
	inst = aip.text.trim(inst_content)

	return meta, inst
end

-- Scans the instruction for inline file references (e.g., ![text](path)) to use as attachments.
-- Returns an array of attachment tables with file paths and titles.
local function extract_attachments(inst, prompt_dir_rel_path)
	local attachments = nil
	if aip.md.extract_refs then -- api from api v0.8.10
		local md_refs = aip.md.extract_refs(inst)

		if #md_refs > 0 then
			attachments = {}
			for _, md_ref in ipairs(md_refs) do
				if md_ref.inline and md_ref.kind == "File" then
					local file_path = prompt_dir_rel_path .. "/" .. md_ref.target;
					file_path = aip.path.resolve(file_path)
					table.insert(attachments, {
						file_source = file_path,
						title       = md_ref.text,
					})
				end
			end
		end
	end
	return attachments
end

-- Resolves knowledge, structure, context, and working file globs from metadata into file lists.
-- Uses the metadata 'base_dir' for workspace-relative lookups.
local function resolve_refs(meta)
	local u_utils = require("utils_data")
	local knowledge_refs = nil
	if u_utils.is_not_empty(meta.knowledge_globs) then
		knowledge_refs = aip.file.list(meta.knowledge_globs, { base_dir = CTX.WORKSPACE_DIR })
	end

	local base_dir = meta.base_dir
	local context_refs = nil
	local structure_refs = nil
	local working_refs_list = nil

	if base_dir then
		-- Remove the trailing /
		base_dir = base_dir:gsub("/+$", "")

		if u_utils.is_not_empty(meta.structure_globs) then
			structure_refs = aip.file.list(meta.structure_globs, { base_dir = base_dir })
		end

		if u_utils.is_not_empty(meta.context_globs) then
			context_refs = aip.file.list(meta.context_globs, { base_dir = base_dir })
		end

		if u_utils.is_not_empty(meta.working_globs) then
			working_refs_list = u_utils.compute_working_refs_list(meta.working_globs, base_dir)
		end
	else
		print("INFO: No base_dir, update in place.")
	end

	return knowledge_refs, structure_refs, context_refs, working_refs_list, base_dir
end

-- Determines the file modification strategy (whole, search_replace_auto, udiffx) based on metadata.
-- If write_mode is false, all modification modes are disabled.
local function get_file_content_mode(meta, write_mode)
	local user_file_content_mode = meta.file_content_mode

	local file_content_mode = {}
	if user_file_content_mode then
		if user_file_content_mode == "whole" then
			file_content_mode.whole = true
		elseif user_file_content_mode == "search_replace_auto" then
			file_content_mode.search_replace_auto = true
		elseif user_file_content_mode == "udiffx" then
			file_content_mode.udiffx = true
		else
			return nil,
					"Error file_conent_mode value '" ..
					user_file_content_mode .. "' is invalid.\nCan be 'whole', 'search_replace_auto' or 'udiffx'"
		end
	else
		file_content_mode.search_replace_auto = true
	end

	if write_mode == false then
		file_content_mode.search_replace_auto = false
		file_content_mode.whole = false
		file_content_mode.udiffx = false
	end

	return file_content_mode
end

-- Loads the appropriate Markdown templates for file changes and git commit suggestions.
local function prepare_instructions(file_content_mode, suggest_git_commit)
	local u_tmpl = require("utils_tmpl")
	local instructions = {}

	if file_content_mode.whole then
		instructions.file_content_change = u_tmpl.load_template("file-content-whole.md").content
	elseif file_content_mode.search_replace_auto then
		instructions.file_content_change = u_tmpl.load_template("file-content-search-replace-auto.md").content
	elseif file_content_mode.udiffx then
		instructions.file_content_change = u_tmpl.load_template("file-content-udiffx.md").content
	end

	if suggest_git_commit then
		instructions.suggest_commit = u_tmpl.load_template("suggest-commit.md").content
	end

	return instructions
end

-- Aggregates all global run parameters and configuration into a single base table.
local function build_input_base(params)
	local meta = params.meta

	return {
		instructions                       = params.instructions,
		attachments                        = params.attachments,
		max_files_size_kb                  = meta.max_files_size_kb or CONST.DEFAULT_MAX_FILES_SIZE_KB,
		write_mode                         = params.write_mode,
		file_content_mode                  = params.file_content_mode,
		prompt_file_rel_path               = params.prompt_file_rel_path,
		default_language                   = meta.default_language or "Python",
		knowledge_refs                     = params.knowledge_refs,
		first_part                         = params.first_part,
		include_second_part                = params.include_second_part,
		second_part                        = params.second_part,
		prompt_path                        = params.prompt_path,
		inst                               = params.inst,
		base_dir                           = params.base_dir,
		structure_refs                     = params.structure_refs,
		context_refs                       = params.context_refs,
		prompt_files_path                  = params.prompt_files_path,
		-- prompt explicit caching
		cache_pre_prompts                  = params.cache_pre_prompts,
		cache_knowledge_files              = params.cache_knowledge_files,
		cache_context_files                = params.cache_context_files,
		-- output files
		ai_responses_for_raw_path          = params.ai_responses_for_raw_path,
		ai_responses_for_prompt_path       = params.ai_responses_for_prompt_path,
		last_file_change_fails_report_path = params.last_file_change_fails_report_path,
	}
end

-- Prepares the final inputs for the agent processing pipeline.
-- If multiple working files are defined, it creates one input per working file group.
local function prepare_inputs(working_refs_list, input_base, inst)
	local inputs = {}

	-- If we have working_refs, then, we split input per working_refs (i.e., files)
	if working_refs_list ~= nil and #working_refs_list > 0 then
		for _, working_refs in ipairs(working_refs_list) do
			-- Note: We put the working_file into an array for later, to allow having one input to be multiple files
			if #working_refs > 0 then
				local msg = working_refs[1].path
				if #working_refs > 1 then
					msg = msg .. ", plus " .. (#working_refs - 1) .. " files"
				end
				local _display = "working files (" .. #working_refs .. "): " .. msg .. "\n\n" .. inst
				table.insert(inputs, { base = input_base, working_refs = working_refs, _display = _display })
			end
		end
	else
		inputs = { { base = input_base, _display = inst } }
	end

	return inputs
end

-- === /Support Functions

-- === Public Functions

-- Orchestrates the global initialization of the agent.
-- Handles version checks, prompt parsing, metadata extraction, and file resolution.
-- Returns the prepared list of inputs and the global agent options.
local function run_before_all(inputs)
	local u_utils = require("utils_data")
	local u_tmpl = require("utils_tmpl")
	local u_sub_agent = require("utils_sub_agent")

	-- === Check AIPACK Version
	local version_ok, version_err = check_version()
	if not version_ok then return nil, nil, version_err end

	-- === Init the prompt file if needed
	local pack_id = CTX.PACK_IDENTITY or "local"
	local default_prompt_absolute_dir = CTX.WORKSPACE_AIPACK_DIR .. "/.prompt/" .. pack_id
	local default_prompt_file_path = default_prompt_absolute_dir .. "/coder-prompt.md"

	local input = inputs and inputs[1] or nil

	local prompt_file = u_utils.prep_prompt_file(input, {
		default_prompt_path = default_prompt_file_path
	})

	local paths = prepare_paths(prompt_file.path)

	-- Save the dev plan files only if not present
	u_tmpl.init_fixed_files(paths.prompt_dir)

	-- === Extract data from prompt files
	local first_part, second_part = extract_prompt_parts(prompt_file.content)

	-- === Extract the meta and instruction
	local meta, inst = extract_meta_and_inst(first_part)

	-- === Compute the agent options
	local options = {
		model             = meta.model,
		temperature       = meta.temperature,
		model_aliases     = meta.model_aliases,
		input_concurrency = meta.input_concurrency
	}

	local coder_prompt_dir = aip.path.diff(paths.prompt_dir, CTX.WORKSPACE_DIR)

	-- === Run Sub Agents
	if not is_null(meta.sub_agents) and #meta.sub_agents > 0 then
		local err
		meta, inst, err = u_sub_agent.run_sub_agents("pre", meta, inst, options, coder_prompt_dir)
		meta = meta or {} -- make the type nil check happy

		if err then return nil, nil, err end
		-- recompute options from the meta returned
		options = {
			model             = meta.model,
			temperature       = meta.temperature,
			model_aliases     = meta.model_aliases,
			input_concurrency = meta.input_concurrency
		}
	end

	aip.run.pin("pfile", 0, {
		label = CONST.LABEL_PROMPT_FILE,
		content = paths.prompt_file_rel_path
	})

	-- === Determine if we should skip
	if inst == "" then
		local msg = "Empty instruction. Open & Edit prompt file:\n\n"
		msg = msg .. "➜ " .. paths.prompt_file_rel_path .. "\n\n(And press [r] for Replay)"
		return nil, nil, msg
	end

	-- === Extract the eventual md ref
	local attachments = extract_attachments(inst, paths.prompt_dir)

	-- === Prep the cache files
	clean_and_init_cache(paths)

	local knowledge_refs, structure_refs, context_refs, working_refs_list, base_dir = resolve_refs(meta)

	local write_mode = meta.write_mode or false

	-- === Compute include_second_partby default we include second part if not nil
	local include_second_part = second_part ~= nil
	if write_mode == true then
		-- if write_mode, we do not include second part
		include_second_part = false
	end

	-- === Defined the explicit cache strategy (for Anthropic)
	-- Default false
	local cache_pre_prompts = false
	local cache_knowledge_files = false
	-- NOTE: for now cache_context_files is always off
	--       (make sure cache blocks <= 4 if decide to activate it, per anthropic limitation)
	if meta.cache_explicit then
		cache_pre_prompts = true
		cache_knowledge_files = true
	end

	-- === Compute file_content_mode
	local file_content_mode, err = get_file_content_mode(meta, write_mode)
	if err then return nil, nil, err end

	-- === Suggest Commit
	local suggest_git_commit = false
	if meta.suggest_git_commit ~= nil then
		suggest_git_commit = meta.suggest_git_commit
	else
		suggest_git_commit = write_mode
	end

	local instructions = prepare_instructions(file_content_mode, suggest_git_commit)

	-- === Build the input base
	local input_base = build_input_base({
		meta                               = meta,
		instructions                       = instructions,
		attachments                        = attachments,
		write_mode                         = write_mode,
		file_content_mode                  = file_content_mode,
		prompt_file_rel_path               = paths.prompt_file_rel_path,
		knowledge_refs                     = knowledge_refs,
		first_part                         = first_part,
		include_second_part                = include_second_part,
		second_part                        = second_part,
		prompt_path                        = prompt_file.path,
		inst                               = inst,
		base_dir                           = base_dir,
		structure_refs                     = structure_refs,
		context_refs                       = context_refs,
		prompt_files_path                  = paths.prompt_files_path,
		cache_pre_prompts                  = cache_pre_prompts,
		cache_knowledge_files              = cache_knowledge_files,
		cache_context_files                = false,
		ai_responses_for_raw_path          = paths.ai_responses_for_raw_path,
		ai_responses_for_prompt_path       = paths.ai_responses_for_prompt_path,
		last_file_change_fails_report_path = paths.last_file_change_fails_report_path,
	})

	-- === Preps the inputs
	local final_inputs = prepare_inputs(working_refs_list, input_base, inst)

	-- === Print Run Info
	print_run_info(input_base, working_refs_list, write_mode, meta.input_concurrency)

	return final_inputs, options
end

-- === /Public Functions

return {
	run_before_all = run_before_all
}
