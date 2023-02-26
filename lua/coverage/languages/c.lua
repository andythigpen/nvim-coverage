local M = {}

-- Javascript and Typescript currently use the exact same configuration.
local cpp = require("coverage.languages.cpp")

--- Use the same configuration as javascript
M.config_alias = "cpp"

--- Returns a list of signs to be placed.
M.sign_list = cpp.sign_list

--- Returns a summary report.
M.summary = cpp.summary

--- Loads a coverage report.
M.load = cpp.load

return M
