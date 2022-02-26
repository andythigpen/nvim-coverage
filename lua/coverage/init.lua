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
end

--- Generates a report and places signs.
M.generate_report = function()
	local ftype = vim.bo.filetype

	local ok, lang = pcall(require, "coverage.languages." .. ftype)
	if not ok then
		vim.notify("coverage report not available for filetype " .. ftype)
		return
	end

	lang.generate_report(function(json_data)
		local results = lang.sign_list(config.opts.sign_group, json_data)
		signs.place(results)
	end)
end

--- Toggles signs.
M.toggle = signs.toggle

--- Clears all signs.
M.clear = signs.clear

return M
