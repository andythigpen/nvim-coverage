local M = {}

local Path = require "plenary.path"
local config = require "coverage.config"
local util = require "coverage.util"
local cs = require "coverage.signs"
local lom = require "lxp.lom"

--- Loads a coverage report.
-- @param callback called with results of the coverage report
M.load = function(callback)
    -- Try and load file
    local opt = config.opts.lang.java.coverage_file
    local p = Path:new(util.get_coverage_file(opt))
    if not p:exists() then
        vim.notify("No coverage file exists.", vim.log.levels.INFO)
        return
    end

    local dir_prefix = config.opts.lang.java.dir_prefix .. "/"

    -- Parse into object
    local jacoco = lom.parse(vim.fn.readfile(p.filename))

    -- Failed to parse, ignore.
    if not jacoco then
        vim.notify "Error loading XML"
        return nil
    end

    -- Load xml
    local data = {
        files = {},
        totals = {},
    }

    for _, item in ipairs(jacoco) do
        -- We only really care about ocunter and package
        if item.tag == "counter" then
            -- Global stats
            if item.attr.type == "LINE" then
                data.totals.line = {
                    covered = tonumber(item.attr.covered),
                    missed = tonumber(item.attr.missed),
                }
            elseif item.attr.type == "BRANCH" then
                data.totals.branch = {
                    covered = tonumber(item.attr.covered),
                    missed = tonumber(item.attr.missed),
                }
            end
        elseif item.tag == "package" then
            -- Where the sourcefiles live
            local dir = dir_prefix .. item.attr.name .. "/"
            -- Here's where the source file are stored :)
            for _, srcfile in ipairs(item) do
                if srcfile.tag == "sourcefile" then
                    local fn = dir .. srcfile.attr.name
                    data.files[fn] = {
                        lines = {},
                        totals = {
                            line = { covered = 0, missed = 0 },
                            branch = { covered = 0, missed = 0 },
                        },
                    }
                    -- So, jacoco reports in terms of instructions
                    -- which is neat, but not uh that useful for this purpose.
                    -- I'll mark any sort of missing instructions as missed lines,
                    -- iff no instructions were missed, check if any were covered.
                    -- Also,, it doesn't really specify if stuff is mutually exclusive or not.
                    -- The priority will be
                    --     1. Missed branch
                    --     2. Missed instruction (as line)
                    --     3. Covered branch
                    --     4. Covered instruction (as line)
                    for _, srcdata in ipairs(srcfile) do
                        if srcdata.tag == "line" then
                            local lnr = tonumber(srcdata.attr.nr)
                            assert(lnr, "bad linenumber")

                            local mb = srcdata.attr.mb ~= "0"
                            local mi = srcdata.attr.mi ~= "0"
                            local cb = srcdata.attr.cb ~= "0"
                            local ci = srcdata.attr.ci ~= "0"

                            if mb and cb or mi and ci then
                                data.files[fn].lines[lnr] = "partial"
                            elseif mb or mi then
                                data.files[fn].lines[lnr] = "missed"
                            else
                                data.files[fn].lines[lnr] = "covered"
                            end
                        elseif srcdata.tag == "counter" then
                            if srcdata.attr.type == "LINE" then
                                data.files[fn].totals.line = {
                                    covered = tonumber(srcdata.attr.covered),
                                    missed = tonumber(srcdata.attr.missed),
                                }
                            elseif srcdata.attr.type == "BRANCH" then
                                data.files[fn].totals.branch = {
                                    covered = tonumber(srcdata.attr.covered),
                                    missed = tonumber(srcdata.attr.missed),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    callback(data)
end

--- Returns a list of signs that will be placed in buffers.
-- This method should use the coverage data (previously generated via the load method) to
-- return a list of signs.
-- @return list of signs
M.sign_list = function(data)
    local signs = {}
    local funcs = {
        covered = cs.new_covered,
        partial = cs.new_partial,
        missed = cs.new_uncovered,
    }
    for fn, fdata in pairs(data.files) do
        local bufnr = vim.fn.bufnr(fn, false)
        -- Only do loaded buffers
        if bufnr ~= -1 then
            for lnum, what in pairs(fdata.lines) do
                table.insert(signs, funcs[what](bufnr, lnum))
            end
        end
    end

    return signs
end

--- Returns a summary report.
-- @return summary report
M.summary = function(data)
    local report = { files = {} }
    for fn, fdata in pairs(data.files) do
        local statements = fdata.totals.line.covered + fdata.totals.line.missed
        local rep = {
            filename = fn,
            statements = statements,
            missing = fdata.totals.line.missed,
            branches = fdata.totals.branch.covered + fdata.totals.branch.missed,
            partial = fdata.totals.branch.missed,
            coverage = (1 - fdata.totals.line.missed / statements) * 100,
        }
        -- Avoid nan
        if statements == 0 then
            rep.coverage = 100
        end
        table.insert(report.files, rep)
    end

    report.totals = {
        statements = data.totals.line.covered + data.totals.line.missed,
        missing = data.totals.line.missed,
        branches = data.totals.branch.covered + data.totals.branch.missed,
        partial = data.totals.branch.missed,
    }
    if report.totals.statements == 0 then
        report.totals.coverage = 100
    else
        report.totals.coverage = (1 - report.totals.missing / report.totals.statements) * 100
    end

    return report
end

return M
