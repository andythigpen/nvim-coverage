local M = {}

local config = require("coverage.config")
local signs = require("coverage.signs")
local highlight = require("coverage.highlight")
local summary = require("coverage.summary")
local report = require("coverage.report")
local watch = require("coverage.watch")

--- Setup the coverage plugin.
-- Also defines signs, creates highlight groups.
-- @param config options
M.setup = function(user_opts)
	config.setup(user_opts)
	signs.setup()
	highlight.setup()

	-- add commands
	if config.opts.commands then
		vim.cmd([[
    command! Coverage lua require('coverage').load(true)
    command! CoverageLoad lua require('coverage').load()
    command! CoverageShow lua require('coverage').show()
    command! CoverageHide lua require('coverage').hide()
    command! CoverageToggle lua require('coverage').toggle()
    command! CoverageClear lua require('coverage').clear()
    command! CoverageSummary lua require('coverage').summary()
    ]])
	end
end

--- Loads a coverage report but does not place signs.
--- @param place boolean true to immediately place signs
M.load = function(place)
	local ftype = vim.bo.filetype

	local ok, lang = pcall(require, "coverage.languages." .. ftype)
	if not ok then
		vim.notify("Coverage report not available for filetype " .. ftype)
		return
	end

	local load_lang = function()
		lang.load(function(result)
			if config.opts.load_coverage_cb ~= nil then
				vim.schedule(function()
					config.opts.load_coverage_cb(ftype)
				end)
			end
			report.cache(result, ftype)
			local sign_list = lang.sign_list(result)
			if place then
				signs.place(sign_list)
			else
				signs.cache(sign_list)
			end
		end)
	end

	local lang_config = config.opts.lang[ftype]
	if lang_config == nil then
		lang_config = config.opts.lang[lang.config_alias]
	end
	if lang_config ~= nil and lang_config.coverage_file ~= nil then
		watch.start(lang_config.coverage_file, load_lang)
	end

	signs.clear()
	load_lang()
end

-- Shows signs, if loaded.
M.show = signs.show

-- Hides signs.
M.hide = signs.unplace

--- Toggles signs.
M.toggle = signs.toggle

--- Hides and clears cached signs.
M.clear = function()
	signs.clear()
	watch.stop()
end

--- Displays a pop-up with a coverage summary report.
M.summary = summary.show

return M
