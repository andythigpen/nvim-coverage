local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function(callback)
    local cpp_config = config.opts.lang.cpp

    local p = Path:new(util.get_coverage_file(cpp_config.coverage_file))
    if p:exists() then
        callback(util.lcov_to_table(p))
        return
    end

    local p = Path:new(util.get_coverage_file(cpp_config.xml_coverage_file))
    if p:exists() then
        callback(util.cobertura_to_table(p, cpp_config.path_mappings or {}))
        return
    end

    vim.notify("No coverage file exists.", vim.log.levels.INFO)
end

return M
