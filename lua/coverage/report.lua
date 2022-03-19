local M = {}

local cached = nil
local cached_lang = nil

--- Returns true if there is currently a cached coverage report.
M.is_cached = function()
	return cached ~= nil
end

--- Returns the cached coverage report or nil.
-- The report format is dependent on the language that generated the report.
M.get = function()
	return cached
end

--- Returns the language filetype that generated the report or nil.
M.language = function()
	return cached_lang
end

--- Sets the cached report and language filetype that generated it.
M.cache = function(report, language)
	cached = report
	cached_lang = language
end

--- Clears any cached report.
M.clear = function()
	cached = nil
	cached_lang = nil
end

return M
