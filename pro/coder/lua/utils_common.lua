local function filter_likely_text(files)
	if files == nil or #files == 0 then
		return files
	end

	local first = files[1]
	if first.is_likely_text == nil then
		return files
	end

	local filtered = {}
	for _, f in ipairs(files) do
		if f.is_likely_text ~= false then
			table.insert(filtered, f)
		end
	end
	return filtered
end

return {
	filter_likely_text = filter_likely_text,
}

