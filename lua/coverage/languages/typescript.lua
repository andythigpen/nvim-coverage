local M = {}

-- Javascript and Typescript currently use the exact same configuration.
local javascript = require("coverage.languages.javascript")

--- Use the same configuration as javascript
M.config_alias = "javascript"

--- Returns a list of signs to be placed.
M.sign_list = javascript.sign_list

--- Returns a summary report.
M.summary = javascript.summary

--- Loads a coverage report.
M.load = javascript.load

return M
