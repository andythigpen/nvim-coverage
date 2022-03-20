local M = {}

local Path = require("plenary.path")
local config = require("coverage.config")
local signs = require("coverage.signs")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
-- @param json_data from the generated report
M.sign_list = function(json_data)
	local sign_list = {}
	for fname, cov in pairs(json_data.coverage) do
		local p = Path:new(fname)
		local buffer = vim.fn.bufnr(p:make_relative(), false)
		if buffer ~= -1 then
			for linenr, status in ipairs(cov.lines) do
				local s = nil
				if status ~= nil and status ~= vim.NIL and status >= 1 then
					s = signs.new_covered(buffer, linenr)
				elseif status == 0 then
					s = signs.new_uncovered(buffer, linenr)
				end
				if s ~= nil then
					table.insert(sign_list, s)
				end
			end
		end
	end
	return sign_list
end

--- Loads a coverage report.
-- @param callback called with the list of signs from the coverage report
M.load = function(callback)
	local ruby_config = config.opts.lang.ruby
	local p = Path:new(ruby_config.coverage_file)
	if not p:exists() then
		vim.notify("No coverage file exists.", vim.log.levels.INFO)
		return
	end
	p:read(vim.schedule_wrap(function(data)
		util.safe_decode(data, callback)
	end))
end

--- Returns a summary report.
M.summary = function(json_data)
	local totals = {
		statements = 0,
		missing = 0,
		excluded = nil, -- simplecov JSON report doesn't have this information
		branches = nil,
		partial = nil,
		coverage = 0,
	}
	local files = {}
	for fname, cov in pairs(json_data.coverage) do
		local statements = 0
		local missing = 0
		for _, status in ipairs(cov.lines) do
			totals.statements = totals.statements + 1
			statements = statements + 1
			if status == 0 then
				totals.missing = totals.missing + 1
				missing = missing + 1
			end
		end
		table.insert(files, {
			filename = fname,
			statements = statements,
			missing = missing,
			excluded = nil, -- simplecov JSON report doesn't have this information
			branches = nil,
			partial = nil,
			coverage = ((statements - missing) / statements) * 100.0,
		})
	end
	totals.coverage = ((totals.statements - totals.missing) / totals.statements) * 100.0
	return {
		files = files,
		totals = totals,
	}
end

return M
