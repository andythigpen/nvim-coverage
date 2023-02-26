local M = {}

--- Safely decode JSON and call the callback with decoded data.
-- @param data to decode
-- @param callback to call on decode success
M.safe_decode = function(data, callback)
    local ok, json_data = pcall(vim.fn.json_decode, data)
    if ok then
        callback(json_data)
    else
        vim.notify("Failed to decode JSON coverage data: " .. json_data, vim.log.levels.ERROR)
    end
end

--- Chain two functions together.
-- @param a first method to chain
-- @param b second method to chain
-- @return chained method
M.chain = function(a, b)
    return function(...)
        a(b(...))
    end
end

--- Returns a table containing file parameters.
--- @return FileCoverage
M.new_file_meta = function()
    return {
        summary = {
            covered_lines = 0,
            excluded_lines = 0,
            missing_lines = 0,
            num_statements = 0,
            percent_covered = 0,
        },
        missing_lines = {},
        missing_branches = {},
        executed_lines = {},
        excluded_lines = {},
    }
end

--- Parses an lcov report from path into files.
--- @param path Path
--- @param files table<string, FileCoverage>
local lcov_parser = function(path, files)
    --- Current file
    --- @type string|nil
    local cfile = nil
    --- Current metadata
    --- @type FileCoverage|nil
    local cmeta = nil

    for _, line in ipairs(path:readlines()) do
        if line:match("end_of_record") and cmeta ~= nil and cfile ~= nil then
            -- Commit the current file
            cmeta.summary["excluded_lines"] = 0
            cmeta.summary["percent_covered"] = cmeta.summary.covered_lines / cmeta.summary.num_statements * 100
            files[cfile] = cmeta
            -- Reset variables
            cfile = nil
            cmeta = nil
        elseif line:match("SF:.+") then
            -- SF:<absolute path to the source file>
            cfile = line:gsub("SF:", "")
            cmeta = M.new_file_meta()
        elseif line:match("^DA:%d+,%d+,?.*") and cmeta ~= nil then
            -- DA:<line number>,<execution count>[,<checksum>]
            local ls, ns = line:match("DA:(%d+),(%d+),?.*")
            local l, n = tonumber(ls, 10), tonumber(ns, 10)
            if n > 0 then
                table.insert(cmeta.executed_lines, l)
            else
                table.insert(cmeta.missing_lines, l)
                cmeta.summary.missing_lines = cmeta.summary.missing_lines + 1
            end
        elseif line:match("^BRDA:%d+,%d+,%d+,(%d+|-)") and cmeta ~= nil then
            -- BRDA:<line number>,<block number>,<branch number>,<taken>
            -- Block number and branch number are gcc internal IDs for the branch.
            -- Taken is either '-' if the basic block containing the branch was never
            -- executed or a number indicating how often that branch was taken.
            local ls, ns = line:match("^BRDA:(%d+),%d+,%d+,(%d+|-)")
            local l = tonumber(ls, 10)
            --- @type integer?
            local n = 0
            if ns ~= '-' then
                n = tonumber(ns, 10)
            end
            if n == 0 then
                -- lcov uses internal ids for branch blocks and branch numbers...
                -- it may be possible to map these to line numbers but only the `from` branch number is used currently anyway
                table.insert(cmeta.missing_branches, { l, -1 })
            end
        elseif line:match("^BRF:%d+") and cmeta ~= nil then
            -- BRF:<number of branches found>
            local brf = tonumber(line:gsub("BRF:", ""), 10)
            cmeta.summary.num_branches = brf
        elseif line:match("^BRH:%d+") and cmeta ~= nil then
            -- BRH:<number of branches hit>
            if cmeta.summary.num_branches ~= nil then
                local brh = tonumber(line:gsub("BRH:", ""), 10)
                cmeta.summary.num_partial_branches = cmeta.summary.num_branches - brh
            end
        elseif line:match("LH:%d+") and cmeta ~= nil then
            -- LH:<number of lines with a non-zero execution count>
            local lh = tonumber(line:gsub("LH:", ""), 10)
            cmeta.summary["covered_lines"] = lh
        elseif line:match("LF:%d+") and cmeta ~= nil then
            -- LF:<number of instrumented lines>
            local lf = tonumber(line:gsub("LF:", ""), 10)
            cmeta.summary["num_statements"] = lf
        else
            -- Everything else is uninteresting, just move on...
        end
    end
end

--- Parses a generic report into a files table.
--- @param path Path
--- @param parser fun(path:Path, files:table<string, FileCoverage>)
--- @return CoverageData
M.report_to_table = function(path, parser)
    --- @type table<string, FileCoverage>
    local files = {}

    parser(path, files)

    --- @type CoverageSummary
    local totals = {
        num_statements = 0,
        covered_lines = 0,
        missing_lines = 0,
        excluded_lines = 0,
    }
    for _, meta in pairs(files) do
        totals.num_statements = totals.num_statements + meta.summary.num_statements
        totals.covered_lines = totals.covered_lines + meta.summary.covered_lines
        totals.missing_lines = totals.missing_lines + meta.summary.missing_lines
        totals.excluded_lines = totals.excluded_lines + meta.summary.excluded_lines
    end
    totals.percent_covered = totals.covered_lines / totals.num_statements * 100

    return { meta = {}, totals = totals, files = files }
end

--- Parses a lcov files into a table,
--- see http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php for spec
--- @param path Path
M.lcov_to_table = function(path)
    return M.report_to_table(path, lcov_parser)
end

--- Parses a cobertura file into a table,
--- @param path Path
M.cobertura_to_table = function(path, path_mappings)
    local cobertura_parser = require("coverage.parsers.corbertura")

    return M.report_to_table(path, function(p, f)
      return cobertura_parser(p, f, path_mappings or {})
    end)
end

return M
