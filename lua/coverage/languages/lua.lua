local M = {}

local Path = require("plenary.path")
local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

M.sign_list = common.sign_list

M.summary = common.summary

M.load = function(callback)
    local lua_config = config.opts.lang.lua
    local p = Path:new(util.get_coverage_file(lua_config.coverage_file))
    if not p:exists() then
        vim.notify("No coverage file exists.", vim.log.levels.INFO)
    end
    callback(util.lcov_to_table(p))
end

return M
