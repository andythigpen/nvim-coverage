local M = {}

local config = require("coverage.config")

local highlight = function(group, color)
	local style = color.style and "gui=" .. color.style or "gui=NONE"
	local fg = color.fg and "guifg=" .. color.fg or "guifg=NONE"
	local bg = color.bg and "guibg=" .. color.bg or "guibg=NONE"
	local sp = color.sp and "guisp=" .. color.sp or ""
	local hl = "highlight " .. group .. " " .. style .. " " .. fg .. " " .. bg .. " " .. sp
	vim.cmd(hl)
	if color.link then
		vim.cmd("highlight! link " .. group .. " " .. color.link)
	end
end

local create_highlight_groups = function()
	highlight("CoverageCovered", config.opts.highlights.covered)
	highlight("CoverageUncovered", config.opts.highlights.uncovered)
end

-- Creates default highlight groups.
M.setup = function()
	create_highlight_groups()
end

return M
