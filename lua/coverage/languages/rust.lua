local M = {}

local Path = require("plenary.path")
local config = require("coverage.config")
local signs = require("coverage.signs")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
-- @param json_data from the generated report
M.sign_list = function(json_data)
	local sign_list = {}
	for _, file in ipairs(json_data.source_files) do
		local fname = Path:new(file.name):make_relative()
		local buffer = vim.fn.bufnr(fname, false)
		if buffer ~= -1 then
			for linenr, hits in ipairs(file.coverage) do
				if hits ~= nil and hits ~= vim.NIL then
					if hits > 0 then
						table.insert(sign_list, signs.new_covered(buffer, linenr))
					elseif hits == 0 then
						table.insert(sign_list, signs.new_uncovered(buffer, linenr))
					end
				end
			end
		end
	end
	return sign_list
end

--- Returns a summary report.
M.summary = function(json_data)
	local totals = {
		statements = 0,
		missing = 0,
		excluded = nil,
		branches = 0,
		partial = 0,
		coverage = 0,
	}
	local files = {}
	for _, file in ipairs(json_data.source_files) do
		local statements = 0
		local missing = 0
		local branches = 0
		local partial = 0
		local fname = Path:new(file.name):make_relative()
		for _, hits in ipairs(file.coverage) do
			totals.statements = totals.statements + 1
			statements = statements + 1
			if hits == 0 then
				totals.missing = totals.missing + 1
				missing = missing + 1
			end
		end
		for i = 1, #file.branches - 1, 4 do
			-- format: [line-number, block-number, branch-number, hits]
			local hits = file.branches[i + 3]
			totals.branches = totals.branches + 1
			branches = branches + 1
			if hits == 0 then
				totals.partial = totals.partial + 1
				partial = partial + 1
			end
		end
		table.insert(files, {
			filename = fname,
			statements = statements,
			missing = missing,
			excluded = nil,
			branches = branches,
			partial = partial,
			coverage = ((statements + branches - missing - partial) / (statements + branches)) * 100.0,
		})
	end
	totals.coverage = (
			(totals.statements + totals.branches - totals.missing - totals.partial)
			/ (totals.statements + totals.branches)
		) * 100.0
	return {
		files = files,
		totals = totals,
	}
end

-- From http://lua-users.org/wiki/StringInterpolation.
local interp = function(s, tab)
	return (s:gsub("($%b{})", function(w)
		return tab[w:sub(3, -2)] or w
	end))
end

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function(callback)
	local rust_config = config.opts.lang.rust
	local cwd = vim.fn.getcwd()
	local cmd = rust_config.coverage_command
	if rust_config.project_files_only then
		for _, pattern in ipairs(rust_config.project_files) do
			cmd = cmd .. " --keep-only '" .. pattern .. "'"
		end
	end
	cmd = interp(cmd, { cwd = cwd })
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
			util.safe_decode(stdout, callback)
		end),
	})
end

return M
