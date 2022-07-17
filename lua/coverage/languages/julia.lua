local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function(callback)
	local julia_config = config.opts.lang.julia

	-- Run the coverage command to construct the lcov.info file
	local stderr = ""
	local jobid = vim.fn.jobstart(julia_config.coverage_command, {
		on_stderr = vim.schedule_wrap(function(_, data, _)
			for _, line in ipairs(data) do
				stderr = stderr .. line
			end
		end),
		on_exit = vim.schedule_wrap(function(_, rc, _)
			if rc ~= 0 then
				if stderr:match("Package CoverageTools not found in current path") then
					local msg = "Package CoverageTools not found in current path: "
						.. "Is it installed in the expected environment? You can install it "
						.. "with the following shell command: "
						.. "julia --project=@nvim-coverage -e 'using Pkg; Pkg.add(\"CoverageTools\")'"
					vim.notify(msg, vim.log.levels.ERROR)
				else
					vim.notify(stderr, vim.log.levels.ERROR)
				end
				return
			end
		end),
	})
	for _, rc in ipairs(vim.fn.jobwait({ jobid })) do
		if rc ~= 0 then
			return
		end
	end

	-- Check if the process above resulted in the file as expected
	local p = Path:new(julia_config.coverage_file)
	if not p:exists() then
		vim.notify("No coverage data file exists.", vim.log.levels.INFO)
		return
	end

	-- Parse the lcov file to table and pass to the callback
	callback(util.lcov_to_table(p))
end

return M
