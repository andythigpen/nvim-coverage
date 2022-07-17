local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

local is_pipenv = function()
	return vim.fn.filereadable("Pipfile") ~= 0
end

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

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
		on_exit = vim.schedule_wrap(function(_, exit_code)
			if exit_code ~= 0 then
				if #stderr == 0 then
					stderr = "Failed to generate coverage"
				end
				vim.notify(stderr, vim.log.levels.ERROR)
				return
			elseif #stderr > 0 then
				vim.notify(stderr, vim.log.levels.WARN)
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
