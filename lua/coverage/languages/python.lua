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
local sign_list = function(json_data)
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

--- Generates a coverage report.
-- @param callback called with the list of signs from the coverage report
M.generate = function(callback)
	local python_config = config.opts.lang.python
	local p = Path:new(python_config.data_file)
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
			util.safe_decode(stdout, util.chain(callback, sign_list))
		end),
	})
end

return M
