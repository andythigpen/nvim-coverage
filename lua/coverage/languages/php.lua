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
    local php_config = config.opts.lang.php
    local p = Path:new(util.get_coverage_file(php_config.coverage_file))
    if not p:exists() then
        vim.notify("No coverage file exists.", vim.log.levels.INFO)
        return
    end

    callback(util.cobertura_to_table(p, php_config.path_mappings or {}))
end

return M
