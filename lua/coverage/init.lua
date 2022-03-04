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
    command Coverage lua require('coverage').load()
    command CoverageShow lua require('coverage').show()
    command CoverageHide lua require('coverage').hide()
    command CoverageToggle lua require('coverage').toggle()
    command CoverageClear lua require('coverage').clear()
    ]])
	end
end

--- Loads a coverage report and places signs.
M.load = function()
	local ftype = vim.bo.filetype

	local ok, lang = pcall(require, "coverage.languages." .. ftype)
	if not ok then
		vim.notify("coverage report not available for filetype " .. ftype)
		return
	end

	signs.clear()
	lang.load(signs.place)
end

-- Shows signs, if loaded.
M.show = signs.show

-- Hides signs.
M.hide = signs.unplace

--- Toggles signs.
M.toggle = signs.toggle

--- Hides and clears cached signs.
M.clear = signs.clear

return M
