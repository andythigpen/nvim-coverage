local signs = require("coverage.signs")
local config = require("coverage.config")

describe("signs", function()
    local bufnr = nil
    --- @type SignPlace[]
    local covered = {}

    before_each(function()
        config.setup()
        bufnr = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, {
            "export function hello(): string {",
            'return "world";',
            '}'
        })
        table.insert(covered, signs.new_covered(bufnr, 1))
    end)

    it("places signs in a buffer", function()
        signs.place(covered)
        local placed = vim.fn.sign_getplaced(bufnr, { group = config.opts.sign_group })
        assert.are.equal(1, #placed)
        assert.are.equal(1, #placed[1].signs)
        assert.are.same(config.opts.sign_group, placed[1].signs[1].group)
        assert.are.same(1, placed[1].signs[1].lnum)
        assert.are.same("coverage_covered", placed[1].signs[1].name)
        assert.are.same(config.opts.signs.covered.priority or 10, placed[1].signs[1].priority)
    end)

    it("removes any previously placed signs when calling place again", function()
        signs.place(covered)
        signs.place(covered)
        local placed = vim.fn.sign_getplaced(bufnr, { group = config.opts.sign_group })
        assert.are.equal(1, #placed)
        assert.are.equal(1, #placed[1].signs)
    end)
end)
