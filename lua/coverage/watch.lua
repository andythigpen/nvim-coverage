local M = {}

local config = require("coverage.config")

local fs_event = nil
local debounce_timer = nil

--- @class Event
--- @field change? boolean
--- @field rename? boolean

--- @param fname string filename to watch
--- @param change_cb fun() callback when a file changes
--- @param events? Event previous triggered events
local function watch(fname, change_cb, events)
    if fs_event ~= nil then
        M.stop()
    end

    if vim.fn.filereadable(fname) == 0 then
        vim.defer_fn(function()
            -- if events is nil, default to rename = true to trigger change_cb when the file is readable
            -- this can happen if the file does not initially exist when coverage.load() is called but is created later
            local ev = events or { rename = true }
            watch(fname, change_cb, ev)
        end, config.opts.auto_reload_timeout_ms)
        return
    end

    if events ~= nil and events.rename then
        -- the file was deleted and recreated
        change_cb()
    end

    fs_event = vim.loop.new_fs_event()
    local flags = {
        watch_entry = false,
        stat = false,
        recursive = false,
    }
    ---@diagnostic disable-next-line: unused-local
    local cb = function(err, filename, ev)
        if err then
            vim.notify("Coverage watch error: " .. err, vim.log.levels.ERROR)
            M.stop()
        elseif ev.rename then
            if debounce_timer ~= nil then
                vim.loop.timer_stop(debounce_timer)
            end
            -- reschedule immediately to watch for the file to be recreated
            debounce_timer = vim.defer_fn(function()
                watch(fname, change_cb, ev)
            end, 0)
        else
            if debounce_timer ~= nil then
                vim.loop.timer_stop(debounce_timer)
            end
            debounce_timer = vim.defer_fn(function()
                debounce_timer = nil
                change_cb()
            end, config.opts.auto_reload_timeout_ms)
        end
    end
    vim.loop.fs_event_start(fs_event, fname, flags, cb)
end

--- Starts the file watcher that executes a callback when a file changes.
--- @param fname string filename to watch
--- @param change_cb fun() callback when a file changes
M.start = function(fname, change_cb)
    watch(fname, change_cb)
end

--- Stops the file watcher.
M.stop = function()
    if fs_event ~= nil then
        vim.loop.fs_event_stop(fs_event)
    end
    fs_event = nil
end

return M
