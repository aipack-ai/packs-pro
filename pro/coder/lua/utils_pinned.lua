-- Utilities for pinned globs validation and merging.

-- Validate that a value is nil/null or a list of strings.
-- Returns the value as a string[] (empty table if nil/null), or nil + error message.
-- param_name: string used in error messages (e.g. "context_globs_pre")
local function validate_string_list(value, param_name)
	if is_null(value) then
		return {}
	end

	if type(value) ~= "table" then
		return nil, param_name .. " must be a list of strings, got " .. type(value)
	end

	for i, item in ipairs(value) do
		if type(item) ~= "string" then
			return nil, param_name .. " item #" .. i .. " must be a string, got " .. type(item)
		end
	end

	return value
end

-- Merge pinned pre, auto-selected globs, and pinned post.
-- pinned_pre: string[]
-- selected: string[]
-- pinned_post: string[]
-- returns: string[]
local function merge_pinned(pinned_pre, selected, pinned_post)
	local combined = {}
	for _, v in ipairs(pinned_pre or {}) do
		table.insert(combined, v)
	end
	for _, v in ipairs(selected or {}) do
		table.insert(combined, v)
	end
	for _, v in ipairs(pinned_post or {}) do
		table.insert(combined, v)
	end
	return combined
end

return {
	validate_string_list = validate_string_list,
	merge_pinned         = merge_pinned,
}
