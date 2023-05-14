local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local report = require("coverage.report")
local signs = require("coverage.signs")
local util = require("coverage.util")
local watch = require("coverage.watch")

--- Loads a coverage report from an lcov file but does not place signs.
--- @param file string the path to the lcov file
--- @param place boolean true to immediately place signs
M.load_lcov = function(file, place)
    if file == nil then
        file = config.opts.lcov_file
    end
    if file == nil then
        vim.notify("A path to the lcov file was not supplied.", vim.log.levels.INFO)
        return
    end
    local p = Path:new(file)
    if not p:exists() then
        vim.notify("No coverage file exists.", vim.log.levels.INFO)
        return
    end

    local load_lcov = function()
        if config.opts.load_coverage_cb ~= nil then
            vim.schedule(function()
                config.opts.load_coverage_cb("lcov")
            end)
        end

        local result = util.lcov_to_table(p)

        -- Since we don't know the actual language, use the default common
        -- summary and sign_list.
        report.cache(result, "common")
        local sign_list = common.sign_list(result)
        if place or signs.is_enabled() then
            signs.place(sign_list)
        else
            signs.cache(sign_list)
        end
    end

    watch.start(file, load_lcov)

    -- When signs were enabled, calling load_lcov would disable them.
    -- That didn't seem like good UX to me, so I disabled this.
    -- signs.clear()
    load_lcov()
end


return M
