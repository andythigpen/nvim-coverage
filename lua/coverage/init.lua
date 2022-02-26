local M = {}

local ns = "coverage_"
local opts = {
	highlights = {
		covered = { fg = "#C3E88D" },
		uncovered = { fg = "#F07178" },
	},
	signs = {
		covered = { hl = "CoverageCovered", text = "▎" },
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	sign_group = "coverage",
}

local define_signs = function()
	vim.fn.sign_define(M.sign_name("covered"), {
		text = opts.signs.covered.text,
		texthl = opts.signs.covered.hl,
	})
	vim.fn.sign_define(M.sign_name("uncovered"), {
		text = opts.signs.uncovered.text,
		texthl = opts.signs.uncovered.hl,
	})
end

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
	highlight("CoverageCovered", opts.highlights.covered)
	highlight("CoverageUncovered", opts.highlights.uncovered)
end

--- Setup the coverage plugin.
-- Also defines signs, creates highlight groups.
-- @param config options
M.setup = function(config)
	if config ~= nil then
		vim.tbl_deep_extend("force", opts, config)
	end
	define_signs()
	create_highlight_groups()
end

--- Returns a namespaced sign name.
-- @param name
M.sign_name = function(name)
	return ns .. name
end

--- Generates a report and places signs.
M.generate_report = function()
	-- TODO: get the file type of the buffer
	local ftype = "python"

	local ok, lang = pcall(require, "coverage.languages." .. ftype)
	if not ok then
		return
	end

	lang.generate_report(function(json_data)
		local signs = lang.sign_list(opts.sign_group, json_data)
		vim.fn.sign_placelist(signs)
	end)
end

--- Toggles signs.
M.toggle = function()
	-- TODO
end

--- Clears all signs.
M.clear = function()
	-- TODO
end

return M
