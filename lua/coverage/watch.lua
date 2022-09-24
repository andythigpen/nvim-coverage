local M = {}

local config = require("coverage.config")

local ev_handle = nil
local debounce_timer = nil

--- Starts the file watcher that executes a callback when a file changes.
--- @param fname string filename to watch
--- @param change_cb fun() callback when a file changes
M.start = function(fname, change_cb)
	if ev_handle ~= nil then
		M.stop()
	end
	ev_handle = vim.loop.new_fs_event()
	local flags = {
		watch_entry = false,
		stat = false,
		recursive = false,
	}
	---@diagnostic disable-next-line: unused-local
	local cb = function(err, filename, events)
		if err then
			vim.notify("Coverage watch error: " .. err, vim.log.levels.ERROR)
			M.stop()
		else
			if debounce_timer ~= nil then
				vim.loop.timer_stop(debounce_timer)
			end
			debounce_timer = vim.defer_fn(function()
				if events.rename then
					-- restart the watch on the new file
					M.start(fname, change_cb)
				end
				debounce_timer = nil
				change_cb()
			end, config.opts.auto_reload_timeout_ms)
		end
	end
	vim.loop.fs_event_start(ev_handle, fname, flags, cb)
end

--- Stops the file watcher.
M.stop = function()
	if ev_handle ~= nil then
		vim.loop.fs_event_stop(ev_handle)
	end
	ev_handle = nil
end

return M
