local M = {}

local config = require("coverage.config")
local Path = require("plenary.path")
local report = require("coverage.report")
local window = require("plenary.window.float")

-- Plenary popup window
-- Example format:
-- {
--     border_bufnr = 25,
--     border_win_id = 1020,
--     bufnr = 24,
--     win_id = 1019,
-- }
local popup = nil
-- cached summary report
local summary = nil
-- cached header
local header = nil
-- cached content (data for files in the report)
local content = nil
-- cached footer
local footer = nil
-- help screen toggle
local help_displayed = false
local cached_filename_width = nil
local fixed_col_width = 64 -- this should match the width of header columns below
local min_filename_width = 25 -- the filename column should be at least this wide
local max_col_width = 99 -- string.format doesn't like values larger than this

-- Sort file coverage ascending.
local coverage_ascending = function(a, b)
    if a.coverage == b.coverage then
        return 0
    elseif a.coverage > b.coverage then
        return 1
    end
    return -1
end

-- Sort file coverage descending.
local coverage_descending = function(a, b)
    if a.coverage == b.coverage then
        return 0
    elseif a.coverage > b.coverage then
        return -1
    end
    return 1
end

-- the current sort method
local sort_method = coverage_ascending

--- Returns the buffer number for a filename, if it exists; -1 otherwise.
local get_bufnr = function(filename)
    local p = Path:new(filename)
    return vim.fn.bufnr(p:make_relative(), false)
end

--- Returns the coverage highlight group based on a configured minimum threshold.
local get_cov_hl_group = function(threshold)
    local min_threshold = config.opts.summary.min_coverage
    if min_threshold == 0 then
        return nil
    end
    return threshold >= min_threshold and "CoverageSummaryPass" or "CoverageSummaryFail"
end

--- Returns the width of the filename column based on the popup window & filename widths.
local get_filename_width = function()
    if cached_filename_width ~= nil then
        return cached_filename_width
    end

    local win_width = vim.api.nvim_win_get_width(popup.win_id)

    local filename_width = min_filename_width
    for _, file in ipairs(summary.files) do
        filename_width = vim.fn.max({ filename_width, string.len(file.filename) + 1 })
    end
    -- cap it at the smallest possible to fit in the window (max 99)
    filename_width = vim.fn.min({ filename_width, win_width - fixed_col_width, max_col_width })
    cached_filename_width = filename_width
    return filename_width
end

--- Loads the header lines and highlighting for rendering later.
local load_header = function()
    header = { lines = {}, highlights = {} }
    table.insert(header.lines, "press ? for help")
    table.insert(header.lines, "")
    table.insert(
        header.highlights,
        { hl_group = "CoverageSummaryHeader", line = #header.lines, col_start = 0, col_end = -1 }
    )
    table.insert(
        header.lines,
        string.format(
            "%" .. get_filename_width() .. "s %11s %9s %9s %9s %9s %11s",
            "Module",
            "Statements",
            "Missing",
            "Excluded",
            "Branches",
            "Partial",
            "Coverage"
        )
    )
end

--- Loads the content lines and highlighting for rendering later.
local load_content = function()
    content = { lines = {}, highlights = {} }
    summary.files = vim.fn.sort(summary.files, sort_method)
    for _, file in ipairs(summary.files) do
        local filename = file.filename
        if string.len(filename) > get_filename_width() then
            -- this truncates paths other than first & last ({1, -1}) to 1 character
            filename = Path:new(filename):shorten(1, { 1, -1 })
        end
        local line = string.format(
            "%" .. get_filename_width() .. "s %11s %9s %9s %9s %9s",
            filename,
            file.statements or "",
            file.missing or "",
            file.excluded or "",
            file.branches or "",
            file.partial or "",
            file.coverage or 0
        )
        if file.coverage ~= nil then
            local hl_group = get_cov_hl_group(file.coverage)
            if hl_group ~= nil then
                table.insert(
                    content.highlights,
                    { hl_group = hl_group, line = #content.lines, col_start = #line, col_end = -1 }
                )
            end
            line = string.format("%s %10.0f%%", line, file.coverage)
        else
            line = line .. "-"
        end
        table.insert(content.lines, line)
    end
end

--- Loads the footer lines and highlighting for rendering later.
local load_footer = function()
    footer = { lines = {}, highlights = {} }

    if summary.totals == nil then
        return
    end

    local line = string.format(
        "%" .. get_filename_width() .. "s %11s %9s %9s %9s %9s",
        "Total",
        summary.totals.statements or "",
        summary.totals.missing or "",
        summary.totals.excluded or "",
        summary.totals.branches or "",
        summary.totals.partial or ""
    )

    if summary.totals.coverage ~= nil then
        local hl_group = get_cov_hl_group(summary.totals.coverage)
        if hl_group ~= nil then
            table.insert(
                footer.highlights,
                { hl_group = hl_group, line = #footer.lines, col_start = #line, col_end = -1 }
            )
        end
        line = string.format("%s %10.0f%%", line, summary.totals.coverage)
    else
        line = line .. "-"
    end
    table.insert(footer.lines, line)
    return footer
end

--- Sets the cursor row to the given filename if it matches or the first content line if no match is found.
local focus_file = function(filename)
    local relative = Path:new(filename):make_relative()
    for index, file in ipairs(summary.files) do
        if file.filename == filename or file.filename == relative then
            vim.api.nvim_win_set_cursor(popup.win_id, { #header.lines + index, 0 })
            return
        end
    end

    vim.api.nvim_win_set_cursor(popup.win_id, { #header.lines + 1, 0 })
end

--- Adds a highlight to the popup buffer.
-- @param highlight { hl_group = "", line = 0, col_start = 0, col_end = -1 }
-- @param offset (optional) added to the highlight line
local add_highlight = function(highlight, offset)
    offset = offset or 0
    vim.api.nvim_buf_add_highlight(
        popup.bufnr,
        -1,
        highlight.hl_group,
        highlight.line + offset,
        highlight.col_start,
        highlight.col_end
    )
end

--- Sets the modifiable and readonly buffer options on the popup.
-- @param modifiable (bool)
local set_modifiable = function(modifiable)
    vim.api.nvim_buf_set_option(popup.bufnr, "modifiable", modifiable)
    vim.api.nvim_buf_set_option(popup.bufnr, "readonly", not modifiable)
end

--- Renders the summary report in the popup.
local render_summary = function()
    local lines = {}
    vim.list_extend(lines, header.lines)
    vim.list_extend(lines, content.lines)
    vim.list_extend(lines, footer.lines)
    set_modifiable(true)
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
    vim.cmd("0center 0") -- centers the "press ? for help" text in the window
    set_modifiable(false)

    for _, highlight in ipairs(header.highlights) do
        add_highlight(highlight)
    end
    for _, highlight in ipairs(content.highlights) do
        add_highlight(highlight, #header.lines)
    end
    for _, highlight in ipairs(footer.highlights) do
        add_highlight(highlight, #header.lines + #content.lines)
    end
    help_displayed = false
end

--- Renders the help page in the popup.
local render_help = function()
    local lines = {
        " Keyboard shortcuts",
        "",
        " Toggle help                 ?",
        " Jump to top entry           H",
        " Sort coverage ascending     s",
        " Sort coverage descending    S",
        " Open selected file          <CR>",
        " Close window                <Esc>",
        " Close window                q",
    }
    set_modifiable(true)
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
    set_modifiable(false)
    add_highlight({ hl_group = "CoverageSummaryHeader", line = 0, col_start = 0, col_end = -1 })
    help_displayed = true
end

--- Inserts keymaps into the popup buffer.
local keymaps = function()
    vim.api.nvim_buf_set_keymap(popup.bufnr, "n", "q", ":" .. popup.bufnr .. "bwipeout!<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(popup.bufnr, "n", "<Esc>", ":" .. popup.bufnr .. "bwipeout!<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(popup.bufnr, "n", "H", ":" .. #header.lines + 1 .. "<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(
        popup.bufnr,
        "n",
        "s",
        ":lua require('coverage.summary').sort(false)<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        popup.bufnr,
        "n",
        "S",
        ":lua require('coverage.summary').sort(true)<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        popup.bufnr,
        "n",
        "<CR>",
        ":lua require('coverage.summary').select_item()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        popup.bufnr,
        "n",
        "?",
        ":lua require('coverage.summary').toggle_help()<CR>",
        { silent = true }
    )
end

--- Loads the summary report based on the language filetype.
local load_summary = function()
    -- get summary results based on language filetype
    local json_data = report.get()
    local lang = require("coverage.languages." .. report.language())
    summary = lang.summary(json_data)
end

--- Sets buffer/window options for the popup after creation.
local set_options = function()
    local win_width = vim.api.nvim_win_get_width(popup.win_id)
    vim.api.nvim_buf_set_option(popup.bufnr, "textwidth", win_width)
    vim.api.nvim_buf_set_option(popup.bufnr, "filetype", "coverage")
    vim.api.nvim_win_set_option(popup.win_id, "cursorline", true)
    vim.api.nvim_win_set_option(
        popup.win_id,
        "winhl",
        "Normal:CoverageSummaryNormal,CursorLine:CoverageSummaryCursorLine"
    )
    vim.cmd(string.format(
        [[
    au BufLeave <buffer=%d> lua require('coverage.summary').close()
    ]]   ,
        popup.bufnr
    ))
end

--- Opens the file under the cursor and closes the popup.
M.select_item = function()
    if popup == nil then
        return
    end
    local pos = vim.api.nvim_win_get_cursor(popup.win_id)
    local row = pos[1]
    if row <= #header.lines or row > #header.lines + #content.lines then
        return
    end

    local index = row - #header.lines
    local fname = summary.files[index].filename

    M.close()

    local bufnr = get_bufnr(fname)
    if bufnr == -1 then
        vim.cmd("edit " .. fname)
        require("coverage").load(true)
    else
        vim.api.nvim_win_set_buf(0, bufnr)
    end
end

--- Toggle the help screen in the popup.
M.toggle_help = function()
    if popup == nil then
        return
    end
    if help_displayed then
        render_summary()
    else
        render_help()
    end
end

--- Try to adjust the width percentage to help on smaller screens.
local adjust_width_percentage = function(width_percentage)
    local term_width = vim.o.columns
    local min_table_width = fixed_col_width + min_filename_width
    if term_width <= min_table_width + 20 then
        width_percentage = 1.0
    elseif term_width <= min_table_width + 40 then
        width_percentage = 0.9
    end
    return width_percentage
end

--- Display the coverage report summary popup.
M.show = function()
    if not report.is_cached() then
        vim.notify("Coverage report not loaded.")
        return
    end

    load_summary()

    -- get the current filename before opening a new popup
    local current_filename = vim.api.nvim_buf_get_name(0)
    local border_opts = vim.tbl_deep_extend("force", {}, config.opts.summary.borders)
    border_opts.title = "Coverage Summary"
    if summary.totals ~= nil and summary.totals.coverage ~= nil then
        border_opts.title = string.format("%s: %.0f%%", border_opts.title, summary.totals.coverage)
        local hl_group = get_cov_hl_group(summary.totals.coverage)
        border_opts.titlehighlight = hl_group
    end

    -- get the window options
    local win_opts = vim.tbl_deep_extend("force", {}, config.opts.summary.window)

    popup = window.percentage_range_window(
        adjust_width_percentage(config.opts.summary.width_percentage),
        config.opts.summary.height_percentage,
        win_opts,
        border_opts
    )

    load_header()
    load_content()
    load_footer()

    set_options()
    render_summary()
    keymaps()
    focus_file(current_filename)
end

--- Change the sort method for the coverage report and re-render the content.
M.sort = function(descending)
    sort_method = descending and coverage_descending or coverage_ascending
    load_content()
    render_summary()
end

--- Close the coverage report summary popup.
M.close = function()
    if popup == nil then
        return
    end
    vim.api.nvim_buf_delete(popup.bufnr, { force = true })
    M.win_on_close()
end

--- Clear variables on window close.
M.win_on_close = function()
    if popup == nil then
        return
    end
    cached_filename_width = nil
    summary = nil
    header = nil
    content = nil
    footer = nil
    help_displayed = false
    popup = nil
end

return M
