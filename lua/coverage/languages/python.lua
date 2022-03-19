local M = {}

local Path = require("plenary.path")
local config = require("coverage.config")
local signs = require("coverage.signs")
local util = require("coverage.util")

local is_pipenv = function()
	return vim.fn.filereadable("Pipfile") ~= 0
end

--- Returns a list of signs to be placed.
-- @param json_data from the generated report
M.sign_list = function(json_data)
	local sign_list = {}
	for fname, cov in pairs(json_data.files) do
		local buffer = vim.fn.bufnr(fname, false)
		if buffer ~= -1 then
			for _, lnum in ipairs(cov.executed_lines) do
				table.insert(sign_list, signs.new_covered(buffer, lnum))
			end

			for _, lnum in ipairs(cov.missing_lines) do
				table.insert(sign_list, signs.new_uncovered(buffer, lnum))
			end
		end
	end
	return sign_list
end

--- Returns a summary report.
M.summary = function(json_data)
	local files = {}
	local totals = {
		statements = json_data.totals.num_statements,
		missing = json_data.totals.missing_lines,
		excluded = json_data.totals.excluded_lines,
		branches = json_data.totals.num_branches,
		partial = json_data.totals.num_partial_branches,
		coverage = json_data.totals.percent_covered,
	}
	for fname, cov in pairs(json_data.files) do
		table.insert(files, {
			filename = fname,
			statements = cov.summary.num_statements,
			missing = cov.summary.missing_lines,
			excluded = cov.summary.excluded_lines,
			branches = cov.summary.num_branches,
			partial = cov.summary.num_partial_branches,
			coverage = cov.summary.percent_covered,
		})
	end
	return {
		files = files,
		totals = totals,
	}
end

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function(callback)
	local python_config = config.opts.lang.python
	local p = Path:new(python_config.coverage_file)
	if not p:exists() then
		vim.notify("No coverage data file exists.", vim.log.levels.INFO)
		return
	end

	local cmd = python_config.coverage_command
	if is_pipenv() then
		cmd = "pipenv run " .. cmd
	end
	local stdout = ""
	local stderr = ""
	vim.fn.jobstart(cmd, {
		on_stdout = vim.schedule_wrap(function(_, data, _)
			for _, line in ipairs(data) do
				stdout = stdout .. line
			end
		end),
		on_stderr = vim.schedule_wrap(function(_, data, _)
			for _, line in ipairs(data) do
				stderr = stderr .. line
			end
		end),
		on_exit = vim.schedule_wrap(function()
			if #stderr > 0 then
				vim.notify(stderr, vim.log.levels.ERROR)
				return
			end
			if stdout == "No data to report." then
				vim.notify(stdout, vim.log.levels.INFO)
				return
			end
			util.safe_decode(stdout, callback)
		end),
	})
end

return M
