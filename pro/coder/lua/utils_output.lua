function build_info_lines(ai_response, data)
	local first_line = ">   Info: " .. ai_response.info
	local second_line = ""
	-- Now, see if we can split the `| Model` ina second line.
	local model_index = string.find(first_line, "| Model")
	if model_index then
		-- Extract the substring starting from the '| Model'
		second_line = "\n>  " .. string.sub(first_line, model_index + 2) -- "+ 2" to skip the "| "
		first_line = string.sub(first_line, 1, model_index - 1)
	end

	local content             = first_line .. second_line
	local knowledge_files_num = data.knowledge_files and #data.knowledge_files or 0
	local context_files_num   = data.context_files and #data.context_files or 0
	local working_files_num   = data.working_files and #data.working_files or 0
	content                   = content .. "\n>  Files: Context Files: " .. context_files_num .. " | "
			.. "Working Files: " .. working_files_num .. " | " .. "Knowledge Files: " .. knowledge_files_num

	if data.write_mode then
		content = content ..
				"\n>   Note: write_mode is true, so content below this line will **NOT** be included in next run/prompt."
	else
		content = content ..
				"\n>   Note: write_mode is false, so content below this line **WILL** be included in next run/prompt."
	end
	return content
end

function process_ui_directives(content)
	-- if API not here, then do nothing
	if aip.tag == nil or aip.tag.extract == nil
			or aip.task == nil or aip.task.pin == nil
			or aip.text == nil or aip.text.trim == nil then
		return
	end

	local elems = aip.tag.extract(content, { "suggested_git_command", "aip_to_pin", "missing_files" }) or {}
	if type(elems) ~= "table" then return end

	for _, elem in ipairs(elems) do
		if elem.tag == "suggested_git_command" then
			-- process git commit suggestion
			aip.task.pin("gitc", 0, {
				label   = "Git Commit",
				content = aip.text.trim(elem.content)
			})
		elseif elem.tag == "aip_to_pin" and elem.attrs then
			local name = elem.attrs.name
			local body = aip.text.trim(elem.content or "")
			if name and body ~= "" then
				aip.task.pin(name, 0, {
					label   = name,
					content = body
				})
			end
		elseif elem.tag == "missing_files" then
			local info = aip.tag.extract_as_map(elem.content, { "mf_message", "mf_files" })
			if info.mf_message and info.mf_files then
				local mf_msg = aip.text.trim(info.mf_message.content)
				aip.task.pin("mf_msg", 0, {
					label   = "Missing Info:",
					content = mf_msg
				})
				local mf_files = info.mf_files.content:gsub("^\n", "") -- remove first empty line
				aip.task.pin("mf_files", 0, {
					label   = "Missing Files:",
					content = mf_files
				})
			end
		end
	end
end

-- ==== RETURN

return {
	process_ui_directives = process_ui_directives,
	build_info_lines      = build_info_lines
}
