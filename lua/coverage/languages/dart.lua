local M = {}

local Path = require("plenary.path")
local config = require("coverage.config")
local util = require("coverage.util")
-- Piggyback on everything but the load
local python = require("coverage.languages.python")

--- Returns a list of signs to be placed.
M.sign_list = python.sign_list

--- Returns a summary report.
M.summary = python.summary

--- Loads a coverage report.
-- @param callback called with the results of the coverage report
M.load = function (callback)
  local dart_config = config.opts.lang.dart
  local p = Path:new(dart_config.coverage_file)
  if not p:exists() then
		vim.notify("No coverage file exists.", vim.log.levels.INFO)
		return
  end

  callback(util.lcov_to_table(p))
end

return M
