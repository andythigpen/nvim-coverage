# nvim-coverage

Display coverage information in the sign column.

Currently supports:

- Python: [coverage.py](https://coverage.readthedocs.io/en/6.3.2/index.html)
- Ruby: [SimpleCov](https://github.com/simplecov-ruby/simplecov)

## Installation

```vim
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
	},
	signs = {
		covered = { hl = "CoverageCovered", text = "▎" },     -- change highlight group or text marker
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	sign_group = "coverage", -- customize the sign group name (see :h sign-group)
	lang = {
		python = {
			coverage_file = ".coverage",                -- coverage is read from this file
			coverage_command = "coverage json -q -o -", -- this command converts it to JSON
		},
		ruby = {
			coverage_file = "coverage/coverage.json",   -- coverage is read from this file
		},
	},
})
```
