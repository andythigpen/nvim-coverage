local M = {
	opts = {},
}

local defaults = {
	commands = true,
	highlights = {
		covered = { fg = "#C3E88D" },
		uncovered = { fg = "#F07178" },
		summary_border = { link = "FloatBorder" },
		summary_normal = { link = "NormalFloat" },
		summary_cursor_line = { link = "CursorLine" },
		summary_header = { style = "bold,underline", sp = "fg" },
		summary_pass = { link = "CoverageCovered" },
		summary_fail = { link = "CoverageUncovered" },
	},
	signs = {
		covered = { hl = "CoverageCovered", text = "▎" },
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	sign_group = "coverage",
	summary = {
		width_percentage = 0.70,
		height_percentage = 0.50,
		borders = {
			topleft = "╭",
			topright = "╮",
			top = "─",
			left = "│",
			right = "│",
			botleft = "╰",
			botright = "╯",
			bot = "─",
			highlight = "Normal:CoverageSummaryBorder",
		},
		min_coverage = 80.0,
	},
	lang = {
		python = {
			coverage_file = ".coverage",
			coverage_command = "coverage json -q -o -",
		},
		ruby = {
			coverage_file = "coverage/coverage.json",
		},
		rust = {
			coverage_command = "grcov ${cwd} -s ${cwd} --binary-path ./target/debug/ -t coveralls --branch --ignore-not-existing --token NO_TOKEN",
			project_files_only = true,
			project_files = { "src/*", "tests/*" },
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
