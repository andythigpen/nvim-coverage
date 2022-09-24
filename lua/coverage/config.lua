--- @class Configuration
--- @field auto_reload boolean
--- @field auto_reload_timeout_ms integer
--- @field commands boolean
--- @field lang table
--- @field load_coverage_cb fun(ftype: string)

local M = {
	--- @type Configuration
	opts = {},
}

--- @type Configuration
local defaults = {
	auto_reload = false,
	auto_reload_timeout_ms = 500,
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
	load_coverage_cb = nil,
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

	-- language specific configuration
	lang = {
		dart = {
			coverage_file = "coverage/lcov.info",
		},
		go = {
			coverage_file = "coverage.out",
		},
		javascript = {
			coverage_file = "coverage/lcov.info",
		},
		julia = {
			-- See https://github.com/julia-actions/julia-processcoverage
			coverage_command = "julia --compile=min -O0 -e '" .. [[
                !isdir("src") && (print(stderr, "No src directory found."); exit(1))
                push!(empty!(LOAD_PATH), "@nvim-coverage", "@stdlib")
                using CoverageTools
                LCOV.writefile("lcov.info", process_folder("src"))
            ]] .. "'",
			coverage_file = "lcov.info",
		},
		python = {
			coverage_file = ".coverage",
			coverage_command = "coverage json --fail-under=0 -q -o -",
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
