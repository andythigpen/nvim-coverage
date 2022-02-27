local M = {
	opts = {},
}

local defaults = {
	commands = true,
	highlights = {
		covered = { fg = "#C3E88D" },
		uncovered = { fg = "#F07178" },
	},
	signs = {
		covered = { hl = "CoverageCovered", text = "▎" },
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	sign_group = "coverage",
	lang = {
		python = {
			data_file = ".coverage",
			coverage_command = "coverage json -q -o -",
		},
		ruby = {
			coverage_file = "coverage/coverage.json",
		},
	},
}

--- Setup configuration values.
M.setup = function(config)
	M.opts = vim.tbl_deep_extend("force", M.opts, defaults)
	if config ~= nil then
		M.opts = vim.tbl_deep_extend("force", M.opts, config)
	end
end

return M
