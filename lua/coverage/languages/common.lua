local M = {}

local signs = require("coverage.signs")

--- @class FileCoverage
--- @field excluded_lines integer[] line numbers excluded from the coverage report
--- @field executed_lines integer[] line numbers executed under test
--- @field missing_lines integer[] line numbers not executed under test
--- @field missing_branches integer[][] line numbers partially executed under test
--- @field summary CoverageSummary

--- @class CoverageSummary
--- @field covered_lines integer total number of covered lines
--- @field missing_lines integer total number of uncovered lines
--- @field excluded_lines integer total number of excluded lines
--- @field num_branches integer total number of branches
--- @field num_partial_branches integer total number of partially covered branches
--- @field num_statements integer total number of statements
--- @field percent_covered number percentage of covered lines to total statements

--- @class CoverageData
--- @field files table<string, FileCoverage>
--- @field totals CoverageSummary

--- Returns a list of signs to be placed.
--- @param json_data CoverageData data from the generated report
--- @returns SignPlace[]
M.sign_list = function(json_data)
    --- @type SignPlace[]
    local sign_list = {}
    for fname, cov in pairs(json_data.files) do
        local buffer = vim.fn.bufnr(fname, false)
        if buffer ~= -1 then
            -- group missing branches by `from` line number
            local missing_branches_from = {}
            for _, branch in ipairs(cov.missing_branches) do
                -- branch is { from, to }
                table.insert(missing_branches_from, branch[1])
            end

            for _, lnum in ipairs(cov.executed_lines) do
                -- a line cannot be fully covered if there are executed missing branches from it
                if not vim.tbl_contains(missing_branches_from, lnum) then
                    table.insert(sign_list, signs.new_covered(buffer, lnum))
                end
            end

            for _, lnum in ipairs(cov.missing_lines) do
                table.insert(sign_list, signs.new_uncovered(buffer, lnum))
            end

            for _, lnum in ipairs(missing_branches_from) do
                -- if from is a missing_line, all branches are missing coverage so we can ignore here
                -- otherwise, if the line is not missing but branches are, then the line is partially coverged
                if not vim.tbl_contains(cov.missing_lines, lnum) then
                    table.insert(sign_list, signs.new_partial(buffer, lnum))
                end
            end
        end
    end
    return sign_list
end

--- Returns a summary report.
--- @param json_data CoverageData
M.summary = function(json_data)
    local files = {}
    local totals = {
        statements = json_data.totals.num_statements,
        missing = json_data.totals.missing_lines,
        excluded = json_data.totals.excluded_lines,
        branches = json_data.totals.num_branches,
        partial = json_data.totals.num_partial_branches,
        coverage = json_data.totals.percent_covered,
    }
    for fname, cov in pairs(json_data.files) do
        table.insert(files, {
            filename = fname,
            statements = cov.summary.num_statements,
            missing = cov.summary.missing_lines,
            excluded = cov.summary.excluded_lines,
            branches = cov.summary.num_branches,
            partial = cov.summary.num_partial_branches,
            coverage = cov.summary.percent_covered,
        })
    end
    return {
        files = files,
        totals = totals,
    }
end

return M
