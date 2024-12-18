local M = {}

local Path = require "plenary.path"
local config = require "coverage.config"
local util = require "coverage.util"
local cs = require "coverage.signs"
local lom = require "neotest.lib.xml"

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

    local dir_prefix = Path:new(config.opts.lang.java.dir_prefix .. "/").filename

    -- Parse into object
    local jacoco = lom.parse(table.concat(vim.fn.readfile(p.filename), ""))

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

    local get_attr_by_type_name = function(tag, type_name)
        if not tag then
            return nil
        end
        for _, value in ipairs(tag) do
            if value._attr.type == type_name then
                return value._attr
            end
        end
        return nil
    end

    -- Global stats
    -- obtains the total counters
    local counter = assert(jacoco.report.counter, "not able to readjacoco.report.counter")

    local global_lines = get_attr_by_type_name(counter, "LINE")
    if global_lines then
        data.totals.line = {
            covered = tonumber(global_lines.covered),
            missed = tonumber(global_lines.missed),
        }
    end

    local branch = get_attr_by_type_name(counter, "BRANCH")
    if branch then
        data.totals.branch = {
            covered = tonumber(branch.covered),
            missed = tonumber(branch.missed),
        }
    end


    -- obtains fine grained data
    local packages = assert(jacoco.report.package, "not able to read jacoco.report.package")
    assert(type(packages) == "table")
    for _, pack in ipairs(packages) do
        local dir = dir_prefix .. pack._attr.name

        -- classes
        for _, class in ipairs(pack.class) do
            local filename = Path:new(dir .. "/" .. class._attr.sourcefilename).filename -- with .java

            -- set file total counters
            local file_total_lines = get_attr_by_type_name(class.counter, "LINE")
            local file_total_branches = get_attr_by_type_name(class.counter, "BRANCH")
            data.files[filename] = {
                lines = {},
                totals = {
                    line = {
                        covered = file_total_lines and file_total_lines.covered or 0,
                        missed = file_total_lines and file_total_lines.missed or 0
                    },
                    branch = {
                        covered = file_total_branches and file_total_branches.covered or  0,
                        missed = file_total_branches and file_total_branches.missed or 0
                    },
                },
            }


        end

        for _, src_file in ipairs(pack.sourcefile) do
            local lines = src_file.line
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
            if lines then
                for _, line in ipairs(lines) do
                    local line_number = assert(tonumber(line._attr.nr))
                    local filename = Path:new(dir .. "/" .. src_file._attr.name).filename

                    local mb = assert(line._attr.mb) ~= "0"
                    local mi = assert(line._attr.mi) ~= "0"
                    local cb = assert(line._attr.cb) ~= "0"
                    local ci = assert(line._attr.ci) ~= "0"

                    if mb and cb or mi and ci then
                        data.files[filename].lines[line_number] = "partial"
                    elseif mb or mi then
                        data.files[filename].lines[line_number] = "missed"
                    else
                        data.files[filename].lines[line_number] = "covered"
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
