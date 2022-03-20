# nvim-coverage

Displays coverage information in the sign column.

![markers](https://user-images.githubusercontent.com/542263/159128715-32e6eddf-5f9f-4853-9e2b-abd66bbf01d4.png)

Displays a coverage summary report in a pop-up window.

![summary](https://user-images.githubusercontent.com/542263/159128732-8189b89d-4f71-4a34-8c6a-176e40fcd48d.png)

Currently supports:

- Python: [coverage.py](https://coverage.readthedocs.io/en/6.3.2/index.html)
- Ruby: [SimpleCov](https://github.com/simplecov-ruby/simplecov)
- Rust: [grcov](https://github.com/mozilla/grcov#usage)

## Installation

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'andythigpen/nvim-coverage'
```

The following lua is required to configure the plugin after installation.
```lua
require("coverage").setup()
```

## Configuration

Default Configuration:

```lua
require("coverage").setup({
	commands = true, -- create commands
	highlights = {
		covered = { fg = "#C3E88D" },   -- supports style, fg, bg, sp (see :h highlight-gui)
		uncovered = { fg = "#F07178" },

    -- summary report pop-up highlight groups
		summary_border = { link = "FloatBorder" },
		summary_normal = { link = "NormalFloat" },
		summary_cursor_line = { link = "CursorLine" },
		summary_header = { style = "bold,underline", sp = "bg" },
		summary_pass = { link = "CoverageCovered" },
		summary_fail = { link = "CoverageUncovered" },
	},
	signs = {
		covered = { hl = "CoverageCovered", text = "▎" },     -- change highlight group or text marker
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	sign_group = "coverage", -- customize the sign group name (see :h sign-group)
	summary = {
		width_percentage = 0.75,  -- width of pop-up (<= 1.0)
		height_percentage = 0.50, -- height of pop-up (<= 1.0) 
		borders = {               -- pop-up borders 
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
		min_coverage = 80.0,      -- minimum coverage threshold (used for highlighting)
	},
	lang = {
		python = {
			coverage_file = ".coverage",                -- coverage is read from this file
			coverage_command = "coverage json -q -o -", -- this command converts it to JSON
		},
		ruby = {
			coverage_file = "coverage/coverage.json",   -- coverage is read from this file
		},
		rust = {
			-- source dir will be set based on vim cwd
			coverage_command = "grcov ${cwd} -s ${cwd} --binary-path ./target/debug/ -t coveralls --branch --ignore-not-existing --token NO_TOKEN",
			project_files_only = true,                  -- only display project files if true
			project_files = { "src/*", "tests/*" },     -- list of patterns used to filter the report when project_files_only is true
		},
	},
})
```

## Extending to other languages

1. Create a new lua module matching the pattern `coverage.languages.<filetype>` where `<filetype>` matches the vim filetype for the coverage language (ex. python).
2. Implement the required methods listed below.

Required methods:
```lua
local M = {}

--- Loads a coverage report.
-- This method should perform whatever steps are necessary to generate a coverage report.
-- The coverage report results should passed to the callback, which will be cached by the plugin.
-- @param callback called with results of the coverage report
M.load = function(callback)
  -- TODO: callback(results)
end

--- Returns a list of signs that will be placed in buffers.
-- This method should use the coverage data (previously generated via the load method) to 
-- return a list of signs.
-- @return list of signs
M.sign_list = function(data)
  -- TODO: generate a list of signs using:
  -- require("coverage.signs").new_covered(bufnr, linenr)
  -- require("coverage.signs").new_uncovered(bufnr, linenr)
end

--- Returns a summary report.
-- @return summary report
M.summary = function(data)
  -- TODO: generate a summary report in the format
  return {
    files = {
      { -- all fields, except filename, are optional - the report will be blank if the field is nil
        filename = fname,            -- filename displayed in the report
        statements = statements,     -- number of total statements in the file
        missing = missing,           -- number of lines missing coverage (uncovered) in the file
        excluded = excluded,         -- number of lines excluded from coverage reporting in the file
        branches = branches,         -- number of total branches in the file
        partial = partial_branches,  -- number of branches that are partially covered in the file
        coverage = coverage,         -- coverage percentage (float) for this file
      }
    },
    totals = { -- optional
      statements = total_statements,     -- number of total statements in the report
      missing = total_missing,           -- number of lines missing coverage (uncovered) in the report
      excluded = total_excluded,         -- number of lines excluded from coverage reporting in the report
      branches = total_branches,         -- number of total branches in the report
      partial = total_partial_branches,  -- number of branches that are partially covered in the report
      coverage = total_coverage,         -- coverage percentage to display in the report
    }
  }
end

return M
```
