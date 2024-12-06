local config = require("coverage.config")
local Path = require("plenary.path")
local util = require("coverage.util")
local signs = require("coverage.signs")

local M = {}

M.load = function(callback)
  local swift_config = config.opts.lang.swift
  local p = Path:new(util.get_coverage_file(swift_config.coverage_file))
  if not p:exists() then
    vim.notify("No coverage file exists.", vim.log.levels.INFO)
    return
  end
  p:read(vim.schedule_wrap(function(data)
    util.safe_decode(data, callback)
  end))
end

M.sign_list = function(data)
  local sign_list = {}
  for _, datum in ipairs(data.data) do
    for _, file in ipairs(datum.files) do
      local fname = Path:new(file.filename):make_relative()
      local buffer = vim.fn.bufnr(fname, false)
      if buffer ~= -1 then
        local last_sign_line = -1
        local last_sign_covered = nil
        local segment = nil
        for _, next_segment in ipairs(file.segments) do
          if segment ~= nil then
            local line, _, count, has_count = unpack(segment)
            if has_count then
              local next_line = next_segment[1]
              local covered = count > 0
              for i = line, next_line do
                if i == last_sign_line then
                  if last_sign_covered ~= nil and last_sign_covered ~= covered then
                    sign_list[#sign_list] = signs.new_partial(buffer, i)
                    last_sign_covered = nil
                  end
                else
                  if covered then
                    table.insert(sign_list, signs.new_covered(buffer, i))
                  else
                    table.insert(sign_list, signs.new_uncovered(buffer, i))
                  end
                  last_sign_covered = covered
                end
              end
              last_sign_line = next_line
            end
          end
          segment = next_segment
        end
      end
    end
  end
  return sign_list
end

M.summary = function(data)
  local totals = {
    statements = 0,
    missing = 0,
  }
  local files = {}
  for _, d in ipairs(data.data) do
    for _, f in ipairs(d.files) do
      local fname = Path:new(f.filename):make_relative()
      if fname:match("^%.build/") then
        goto next_file
      end
      table.insert(files, {
        filename = fname,
        statements = f.summary.lines.count,
        missing = f.summary.lines.count - f.summary.lines.covered,
        coverage = f.summary.lines.percent,
      })
      ::next_file::
    end
    totals.statements = totals.statements + d.totals.lines.count
    totals.missing = totals.missing + (d.totals.lines.count - d.totals.lines.covered)
  end
  totals.coverage = (totals.statements - totals.missing) / totals.statements * 100.0
  return {
    files = files,
    totals = totals,
  }
end

return M
