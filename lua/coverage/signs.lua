local M = {}
local config = require("coverage.config")

local ns = "coverage_"
local enabled = false
local cached_signs = nil

--- @class Sign
--- @field hl string name of the highlight group
--- @field text string text to place in sign column
--- @field priority integer? optional priority (default 10; highest wins)

--- @class SignPlace
--- @field buffer string|integer
--- @field group string
--- @field id? integer
--- @field lnum integer
--- @field name string
--- @field priority integer

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
--- @param name string
M.name = function(name)
	return ns .. name
end

--- Caches signs but does not place them.
--- @param signs SignPlace[] (:h sign_placelist)
M.cache = function(signs)
	M.unplace()
	cached_signs = signs
end

--- Places a list of signs
--- @param signs SignPlace[] (:h sign_placelist)
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

--- Displays cached signs.
M.show = function()
	if enabled or cached_signs == nil then
		return
	end
	M.place(cached_signs)
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
--- @param buffer string|integer buffer name or id
--- @param lnum integer line number
--- @return SignPlace
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
--- @param buffer string|integer buffer name or id
--- @param lnum integer line number
--- @return SignPlace
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
