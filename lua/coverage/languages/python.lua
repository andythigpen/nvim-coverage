local M = {}

local config = require("coverage.config")
local signs = require("coverage.signs")

local is_pipenv = function()
	return vim.fn.filereadable("Pipfile") ~= 0
end

--- Generates a coverage report.
-- @param callback called with the decoded JSON coverage report when complete
M.generate_report = function(callback)
	local cmd = "coverage json -q -o -"
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
			callback(vim.fn.json_decode(stdout))
		end),
	})
end

--- Returns a list of signs to be placed.
-- @param json_data from the generated report
M.sign_list = function(json_data)
	local group = config.opts.sign_group
	local sign_list = {}
	for fname, cov in pairs(json_data.files) do
		local buffer = vim.fn.bufnr(fname, false)
		if buffer ~= -1 then
			for _, lnum in ipairs(cov.executed_lines) do
				table.insert(sign_list, {
					buffer = buffer,
					group = group,
					lnum = lnum,
					name = signs.name("covered"),
					priority = config.opts.signs.covered.priority or 10,
				})
			end

			for _, lnum in ipairs(cov.missing_lines) do
				table.insert(sign_list, {
					buffer = buffer,
					group = group,
					lnum = lnum,
					name = signs.name("uncovered"),
					priority = config.opts.signs.uncovered.priority or 10,
				})
			end
		end
	end
	return sign_list
end

return M
