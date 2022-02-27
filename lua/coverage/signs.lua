local M = {}
local config = require("coverage.config")

local ns = "coverage_"
local enabled = false
local cached_signs = nil

--- Defines signs.
M.setup = function()
	vim.fn.sign_define(M.name("covered"), {
		text = config.opts.signs.covered.text,
		texthl = config.opts.signs.covered.hl,
	})
	vim.fn.sign_define(M.name("uncovered"), {
		text = config.opts.signs.uncovered.text,
		texthl = config.opts.signs.uncovered.hl,
	})
end

--- Returns a namespaced sign name.
-- @param name
M.name = function(name)
	return ns .. name
end

--- Places a list of signs
-- @param signs list (reference sign_placelist)
M.place = function(signs)
	vim.fn.sign_placelist(signs)
	enabled = true
	cached_signs = signs
end

--- Unplaces all coverage signs.
M.unplace = function()
	vim.fn.sign_unplace(config.opts.sign_group)
	enabled = false
end

--- Returns true if coverage signs are currently shown.
M.is_enabled = function()
	return enabled
end

--- Toggles the visibility of coverage signs.
M.toggle = function()
	if enabled then
		M.unplace()
	elseif cached_signs ~= nil then
		M.place(cached_signs)
	end
end

--- Turns off coverage signs and removes cached results.
M.clear = function()
	M.unplace()
	cached_signs = nil
end

--- Returns a new covered sign in the format used by sign_placelist.
-- @return sign
M.new_covered = function(buffer, lnum)
	return {
		buffer = buffer,
		group = config.opts.sign_group,
		lnum = lnum,
		name = M.name("covered"),
		priority = config.opts.signs.covered.priority or 10,
	}
end

--- Returns a new uncovered sign in the format used by sign_placelist.
-- @return sign
M.new_uncovered = function(buffer, lnum)
	return {
		buffer = buffer,
		group = config.opts.sign_group,
		lnum = lnum,
		name = M.name("uncovered"),
		priority = config.opts.signs.covered.priority or 10,
	}
end

return M
