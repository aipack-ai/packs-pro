-- Utilities for pinned globs normalization, deduplication, and merging.

-- Stable dedupe: preserves first occurrence order, removes duplicates.
-- items: string[]
-- returns: string[]
local function dedupe(items)
	if not items or #items == 0 then return {} end
	local seen = {}
	local result = {}
	for _, v in ipairs(items) do
		if not seen[v] then
			seen[v] = true
			table.insert(result, v)
		end
	end
	return result
end

-- Normalize a pinned_globs value from user config into { pre = string[], post = string[] }.
-- Accepts:
--   nil/null        -> { pre = {}, post = {} }
--   string[]        -> { pre = <list>, post = {} }  (shorthand)
--   { pre?, post? } -> validated and returned
-- Returns normalized table or nil, error_message
-- param_name: string used in error messages (e.g. "context_globs_pinned")
local function normalize_pinned_globs(value, param_name)
	if is_null(value) then
		return { pre = {}, post = {} }
	end

	if type(value) ~= "table" then
		return nil, param_name .. " must be a list of strings or an object with 'pre'/'post' keys, got " .. type(value)
	end

	-- Detect if it's a sequential array (list) vs an object
	-- A list has numeric keys starting at 1; an object has string keys like "pre"/"post"
	local is_list = false
	if #value > 0 then
		-- Could be a list or an object with numeric keys
		-- Check if first element is a string (list shorthand) or if pre/post keys exist
		if type(value[1]) == "string" then
			is_list = true
		elseif value.pre ~= nil or value.post ~= nil then
			is_list = false
		else
			-- Has numeric keys but first is not string
			return nil, param_name .. " list items must be strings"
		end
	elseif value.pre ~= nil or value.post ~= nil then
		is_list = false
	else
		-- Empty table, treat as empty list
		return { pre = {}, post = {} }
	end

	if is_list then
		-- Shorthand: list of strings -> treat as pre
		-- Validate all items are strings
		for i, item in ipairs(value) do
			if type(item) ~= "string" then
				return nil, param_name .. " list item #" .. i .. " must be a string, got " .. type(item)
			end
		end
		-- Check no pre/post keys mixed in
		if value.pre ~= nil or value.post ~= nil then
			return nil, param_name ..
				" cannot mix list shorthand with 'pre'/'post' keys. Use either a plain list (treated as 'pre') or an object with 'pre' and/or 'post'."
		end
		return { pre = value, post = {} }
	end

	-- Object form with pre/post
	local result = { pre = {}, post = {} }

	if not is_null(value.pre) then
		if type(value.pre) ~= "table" then
			return nil, param_name .. ".pre must be a list of strings, got " .. type(value.pre)
		end
		for i, item in ipairs(value.pre) do
			if type(item) ~= "string" then
				return nil, param_name .. ".pre item #" .. i .. " must be a string, got " .. type(item)
			end
		end
		result.pre = value.pre
	end

	if not is_null(value.post) then
		if type(value.post) ~= "table" then
			return nil, param_name .. ".post must be a list of strings, got " .. type(value.post)
		end
		for i, item in ipairs(value.post) do
			if type(item) ~= "string" then
				return nil, param_name .. ".post item #" .. i .. " must be a string, got " .. type(item)
			end
		end
		result.post = value.post
	end

	return result
end

-- Merge pinned pre, auto-selected globs, and pinned post with deduplication.
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
	return dedupe(combined)
end

return {
	dedupe                 = dedupe,
	normalize_pinned_globs = normalize_pinned_globs,
	merge_pinned           = merge_pinned,
}
