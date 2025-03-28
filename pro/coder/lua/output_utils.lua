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

    local content = first_line .. second_line
    local knowledge_files_num = data.knowledge_files and #data.knowledge_files or 0
    local context_files_num   = data.context_files and #data.context_files or 0
    local working_files_num   = data.working_files and #data.working_files or 0
    content = content .. "\n>  Files: Context Files: " .. context_files_num .. " | " 
              .. "Working Files: " .. working_files_num .. " | " .. "Knowledge Files: " .. knowledge_files_num
    return content
end

return {
  build_info_lines = build_info_lines
}