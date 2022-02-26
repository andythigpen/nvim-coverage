local M = {}

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

M.sign_list = function(group, json_data)
	local signs = {}
	for fname, cov in pairs(json_data.files) do
		local buffer = vim.fn.bufnr(fname, false)
		if buffer ~= -1 then
			for _, lnum in ipairs(cov.executed_lines) do
				table.insert(signs, {
					buffer = buffer,
					group = group,
					lnum = lnum,
					name = "coverage_covered", -- TODO: use helper method
					-- TODO: prioritiy
				})
			end

			for _, lnum in ipairs(cov.missing_lines) do
				table.insert(signs, {
					buffer = buffer,
					group = group,
					lnum = lnum,
					name = "coverage_uncovered", -- TODO: use helper method
					-- TODO: prioritiy
				})
			end
		end
		P(fname)
		P(cov)
	end
	P(signs)
	return signs
end

return M
