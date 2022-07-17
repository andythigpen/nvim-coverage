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

--- Parses a lcov files into a table,
--- see http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php for spec
--- @param path Path
M.lcov_to_table = function(path)
	local files = {}
	local function new_file_meta()
		return {
			summary = {},
			missing_lines = {},
			executed_lines = {},
			excluded_lines = {},
		}
	end

	local cfile = nil -- Current file
	local cmeta = nil -- Current metadata

	for _, line in ipairs(path:readlines()) do
		if line:match("end_of_record") then
			-- Commit the current file
			cmeta.summary["excluded_lines"] = 0
			cmeta.summary["percent_covered"] = cmeta.summary.covered_lines / cmeta.summary.num_statements * 100
			files[cfile] = cmeta
			-- Reset variables
			cfile = nil
			cmeta = nil
		elseif line:match("SF:.+") then
			-- SF:<absolute path to the source file>
			cfile = line:gsub("SF:", "")
			cmeta = new_file_meta()
		elseif line:match("DA:%d+,%d+,?.*") then
			-- DA:<line number>,<execution count>[,<checksum>]
			local ls, ns = line:match("DA:(%d+),(%d+),?.*")
			local l, n = tonumber(ls), tonumber(ns)
			if n > 0 then
				table.insert(cmeta.executed_lines, l)
			else
				table.insert(cmeta.missing_lines, l)
			end
		elseif line:match("LH:%d+") then
			-- LH:<number of lines with a non-zero execution count>
			local lh = tonumber((line:gsub("LH:", "")))
			cmeta.summary["covered_lines"] = lh
		elseif line:match("LF:%d+") then
			-- LF:<number of instrumented lines>
			local lf = tonumber((line:gsub("LF:", "")))
			cmeta.summary["num_statements"] = lf
		else
			-- Everything else is uninteresting, just move on...
		end
	end

	-- Compute global summary
	local totals = { num_statements = 0, covered_lines = 0, excluded_lines = 0 }
	for _, meta in pairs(files) do
		totals.num_statements = totals.num_statements + meta.summary.num_statements
		totals.covered_lines = totals.covered_lines + meta.summary.covered_lines
		totals.excluded_lines = totals.excluded_lines + meta.summary.excluded_lines
	end
	totals.percent_covered = totals.covered_lines / totals.num_statements * 100

	return { meta = {}, totals = totals, files = files }
end

return M
