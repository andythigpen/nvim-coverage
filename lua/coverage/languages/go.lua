local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

-- the fields are: name.go:line.column,line.column numberOfStatements count
-- see https://github.com/golang/go/blob/0104a31b8fbcbe52728a08867b26415d282c35d2/src/cmd/cover/profile.go#L115
-- and https://github.com/golang/go/blob/master/src/testing/cover.go#L102
local line_re = "^(.+):(%d+)%.%d+,(%d+)%.%d+ (%d+) (%d+)$"

-- for parsing the module name from go.mod
local mod_name_re = "^module (.*)$"

local get_module_name = function()
	local p = Path:new("go.mod")
	if not p:exists() then
		return ""
	end
	local lines = p:readlines()
	for _, line in ipairs(lines) do
		if line:match(mod_name_re) then
			local name = line:match(mod_name_re)
			name = name:gsub("%-", "%%-")
			name = name:gsub("%.", "%%.")
			name = name:gsub("%+", "%%+")
			name = name:gsub("%?", "%%?")
			return name
		end
	end
	return ""
end

--- Parses a coverprofile formatted file
--- @param path Path
--- @param files table<string, FileCoverage>
local parse_coverprofile = function(path, files)
	local lines_by_filename = {}
	local lines = path:readlines()
	local mod_name = get_module_name()
	for _, line in ipairs(lines) do
		if line:match("mode:.*") then
			-- do nothing
		elseif line:match(line_re) then
			-- example/main.go:3.14,5.2 0 0
			local fname, line_start, line_end, _, count = line:match(line_re)
			fname = fname:gsub(mod_name .. "/", "", 1)
			line_start = tonumber(line_start)
			line_end = tonumber(line_end)
			count = tonumber(count)
			if lines_by_filename[fname] == nil then
				lines_by_filename[fname] = {}
			end
			for linenr = line_start, line_end do
				lines_by_filename[fname][linenr] = (lines_by_filename[fname][linenr] or 0) + count
			end
		else
			-- do nothing
		end
	end

	for fname, linenrs in pairs(lines_by_filename) do
		local file = util.new_file_meta()
		for linenr, count in pairs(linenrs) do
			if count == 0 then
				table.insert(file.missing_lines, linenr)
			else
				table.insert(file.executed_lines, linenr)
				file.summary.covered_lines = file.summary.covered_lines + 1
			end
			file.summary.num_statements = file.summary.num_statements + 1
		end
		file.summary.percent_covered = file.summary.covered_lines / file.summary.num_statements * 100
		files[fname] = file
	end
end

--- Loads a coverage report.
--- @param callback function called with the results of the coverage report
M.load = function(callback)
	local go_config = config.opts.lang.go
	local p = Path:new(go_config.coverage_file)
	if not p:exists() then
		vim.notify("No coverage file exists.", vim.log.levels.INFO)
		return
	end

	callback(util.report_to_table(p, parse_coverprofile))
end

return M
