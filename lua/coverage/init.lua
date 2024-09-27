local M = {}

local config = require("coverage.config")
local signs = require("coverage.signs")
local highlight = require("coverage.highlight")
local summary = require("coverage.summary")
local report = require("coverage.report")
local watch = require("coverage.watch")
local lcov = require("coverage.lcov")
local util = require("coverage.util")

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
    command! -nargs=? CoverageLoadLcov lua require('coverage').load_lcov(<f-args>)
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
            if place or signs.is_enabled() then
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

    -- Automatically watch the coverage file for updates when auto_reload is enabled
    -- and when the language setup allows it
    if config.opts.auto_reload and
        lang_config ~= nil and
        lang_config.coverage_file ~= nil and
        not lang_config.disable_auto_reload then
        local coverage_file = util.get_coverage_file(lang_config.coverage_file)
        watch.start(coverage_file, load_lang)
    end

    signs.clear()
    load_lang()
end

-- Load an lcov file
M.load_lcov = lcov.load_lcov

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

--- Jumps to the next sign of the given type.
--- @param sign_type? "covered"|"uncovered"|"partial" Defaults to "covered"
M.jump_next = function(sign_type)
    signs.jump(sign_type, 1)
end

--- Jumps to the previous sign of the given type.
--- @param sign_type? "covered"|"uncovered"|"partial" Defaults to "covered"
M.jump_prev = function(sign_type)
    signs.jump(sign_type, -1)
end

return M
