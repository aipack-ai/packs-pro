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

return M
