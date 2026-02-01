local M = {}

-- Logic from main.aip # Before All

function M.extract_prompt_parts(prompt_content)
	local p_utils = require("prompt_utils")
	-- Split the prompt into inst and content
	local first_part, second_part = p_utils.prep_inst_and_content(prompt_content, "====", { content_is_default = false })

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

function M.extract_meta_and_inst(first_part)
	local meta, inst = aip.md.extract_meta(first_part)
	-- Remove the `> ..` lines
	local _line_blocks, inst_content = aip.text.extract_line_blocks(inst,
		{ starts_with = ">", extrude = "content" })
	inst = aip.text.trim(inst_content)

	return meta, inst
end

function M.extract_attachments(inst, prompt_dir_rel_path)
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

function M.resolve_refs(meta)
	local p_utils = require("prompt_utils")
	local knowledge_refs = nil
	if p_utils.is_not_empty(meta.knowledge_globs) then
		knowledge_refs = aip.file.list(meta.knowledge_globs, { base_dir = CTX.WORKSPACE_DIR })
	end

	local base_dir = meta.base_dir
	local context_refs = nil
	local structure_refs = nil
	local working_refs_list = nil

	if base_dir then
		-- Remove the trailing /
		base_dir = base_dir:gsub("/+$", "")

		if p_utils.is_not_empty(meta.structure_globs) then
			structure_refs = aip.file.list(meta.structure_globs, { base_dir = base_dir })
		end

		if p_utils.is_not_empty(meta.context_globs) then
			context_refs = aip.file.list(meta.context_globs, { base_dir = base_dir })
		end

		if p_utils.is_not_empty(meta.working_globs) then
			working_refs_list = p_utils.compute_working_refs_list(meta.working_globs, base_dir)
		end
	else
		print("INFO: No base_dir, update in place.")
	end

	return knowledge_refs, structure_refs, context_refs, working_refs_list, base_dir
end

function M.get_file_content_mode(meta, write_mode)
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

function M.prepare_instructions(file_content_mode, suggest_git_commit)
	local p_tmpl = require("prompt_tmpl")
	local instructions = {}

	if file_content_mode.whole then
		instructions.file_content_change = p_tmpl.load_template("file-content-whole.md").content
	elseif file_content_mode.search_replace_auto then
		instructions.file_content_change = p_tmpl.load_template("file-content-search-replace-auto.md").content
	elseif file_content_mode.udiffx then
		instructions.file_content_change = p_tmpl.load_template("file-content-udiffx.md").content
	end

	if suggest_git_commit then
		instructions.suggest_commit = p_tmpl.load_template("suggest-commit.md").content
	end

	return instructions
end

function M.build_input_base(params)
	local consts = require("consts")
	local meta = params.meta

	return {
		instructions                       = params.instructions,
		attachments                        = params.attachments,
		max_files_size_kb                  = meta.max_files_size_kb or consts.DEFAULT_MAX_FILES_SIZE_KB,
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

function M.prepare_inputs(working_refs_list, input_base, inst)
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

return M
