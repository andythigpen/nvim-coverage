local M = {}

local opts = {
	covered = { hl = "CoverageCovered", text = "▎" },
	uncovered = { hl = "CoverageUncovered", text = "▎" },
}

M.setup = function(config)
	vim.tbl_deep_extend("force", opts, config)
end

M.parse_xml = function(path)
	-- TODO
end

M.toggle = function()
	-- TODO
end

return M
