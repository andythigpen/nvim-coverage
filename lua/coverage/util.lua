local M = {}

--- Safely decode JSON and call the callback with decoded data.
-- @param data to decode
-- @param callback to call on decode success
M.safe_decode = function(data, callback)
	local ok, json_data = pcall(vim.fn.json_decode, data)
	if ok then
		callback(json_data)
	else
		vim.notify("Failed to decode JSON coverage data: " .. json_data, vim.log.levels.ERROR)
	end
end

--- Chain two functions together.
-- @param a first method to chain
-- @param b second method to chain
-- @return chained method
M.chain = function(a, b)
	return function(...)
		a(b(...))
	end
end

return M
