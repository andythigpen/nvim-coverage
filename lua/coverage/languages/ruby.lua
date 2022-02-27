local M = {}

local Path = require("plenary.path")
local config = require("coverage.config")
local signs = require("coverage.signs")

--- Returns a list of signs to be placed.
-- @param json_data from the generated report
local sign_list = function(json_data)
	local sign_list = {}
	for fname, cov in pairs(json_data.coverage) do
		local p = Path:new(fname)
		local buffer = vim.fn.bufnr(p:make_relative(), false)
		if buffer ~= 1 then
			for linenr, status in ipairs(cov.lines) do
				local s = nil
				if status == 1 then
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

--- Generates a coverage report.
-- @param callback called with the list of signs from the coverage report
M.generate = function(callback)
	local ruby_config = config.opts.lang.ruby
	local p = Path:new(ruby_config.coverage_file)
	if not p:exists() then
		return
	end
	p:read(vim.schedule_wrap(function(data)
		local json_data = vim.fn.json_decode(data)
		callback(sign_list(json_data))
	end))
end

return M
