local M = {
    --- @type Configuration
    opts = {},
}

--- @class Configuration
--- @field auto_reload boolean
--- @field auto_reload_timeout_ms integer
--- @field commands boolean
--- @field highlights HighlightConfig
--- @field load_coverage_cb fun(ftype: string)
--- @field signs SignsConfig
--- @field sign_group string name of the sign group (:h sign_placelist)
--- @field summary SummaryOpts
--- @field lang table
local defaults = {
    auto_reload = false,
    auto_reload_timeout_ms = 500,
    commands = true,

    --- @class HighlightConfig
    --- @field covered Highlight
    --- @field uncovered Highlight
    --- @field partial Highlight
    --- @field summary_border Highlight
    --- @field summary_normal Highlight
    --- @field summary_cursor_line Highlight
    --- @field summary_header Highlight
    --- @field summary_pass Highlight
    --- @field summary_fail Highlight
    highlights = {
        covered = { fg = "#B7F071" },
        uncovered = { fg = "#F07178" },
        partial = { fg = "#AA71F0" },
        summary_border = { link = "FloatBorder" },
        summary_normal = { link = "NormalFloat" },
        summary_cursor_line = { link = "CursorLine" },
        summary_header = { style = "bold,underline", sp = "fg" },
        summary_pass = { link = "CoverageCovered" },
        summary_fail = { link = "CoverageUncovered" },
    },
    load_coverage_cb = nil,

    --- @class SignsConfig
    --- @field covered Sign
    --- @field uncovered Sign
    --- @field partial Sign
    signs = {
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
        partial = { hl = "CoveragePartial", text = "▎" },
    },
    sign_group = "coverage",

    --- @class SummaryOpts
    --- @field width_percentage number
    --- @field height_percentage number
    --- @field min_coverage number
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
        window = {},
        min_coverage = 80.0,
    },

    -- language specific configuration
    lang = {
        cpp = {
            coverage_file = "report.info",
        },
        cs = {
            coverage_file = "TestResults/lcov.info",
        },
        dart = {
            coverage_file = "coverage/lcov.info",
        },
        elixir = {
            coverage_file = "cover/lcov.info",
        },
        go = {
            coverage_file = "coverage.out",
        },
        java = {
            coverage_file = "build/reports/jacoco/test/jacocoTestReport.xml",
            dir_prefix = "src/main/java",
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
            -- julia is disabled because the coverage command itself produces the file to be
            -- watched which leads to an infinite loop (see
            -- https://github.com/andythigpen/nvim-coverage/issues/41)
            disable_auto_reload = true,
        },
        lua = {
            coverage_file = "luacov.report.out",
        },
        python = {
            coverage_file = ".coverage",
            coverage_command = "coverage json --fail-under=0 -q -o -",
            only_open_buffers = false,
        },
        ruby = {
            coverage_file = "coverage/coverage.json",
        },
        rust = {
            coverage_command =
            "grcov ${cwd} -s ${cwd} --binary-path ./target/debug/ -t coveralls --branch --ignore-not-existing --token NO_TOKEN",
            project_files_only = true,
            project_files = { "src/*", "tests/*" },
        },
        php = {
            coverage_file = "coverage/cobertura.xml",
            path_mappings = {},
        }
    },
    lcov_file = nil,
}

--- Setup configuration values.
M.setup = function(config)
    M.opts = vim.tbl_deep_extend("force", M.opts, defaults)
    if config ~= nil then
        M.opts = vim.tbl_deep_extend("force", M.opts, config)
    end
end

return M
