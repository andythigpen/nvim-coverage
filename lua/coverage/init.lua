local M = {}

local config = require("coverage.config")
local signs = require("coverage.signs")
local highlight = require("coverage.highlight")

--- Setup the coverage plugin.
-- Also defines signs, creates highlight groups.
-- @param config options
M.setup = function(user_opts)
	config.setup(user_opts)
	signs.setup()
	highlight.setup()

	-- add commands
	if config.opts.commands then
		vim.cmd([[
    command Coverage lua require('coverage').generate()
    command CoverageToggle lua require('coverage').toggle()
    command CoverageClear lua require('coverage').clear()
    ]])
	end
end

--- Generates a report and places signs.
M.generate = function()
	local ftype = vim.bo.filetype

	local ok, lang = pcall(require, "coverage.languages." .. ftype)
	if not ok then
		vim.notify("coverage report not available for filetype " .. ftype)
		return
	end

	lang.generate(signs.place)
end

--- Toggles signs.
M.toggle = signs.toggle

--- Clears all signs.
M.clear = signs.clear

return M
