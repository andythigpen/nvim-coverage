local signs = require("coverage.signs")

describe("languages.python", function()
    local python_coverage = function(bufname)
        local lines = {
            signs.new_covered(bufname, 1),
            signs.new_covered(bufname, 2),
            signs.new_covered(bufname, 3),
            signs.new_covered(bufname, 4),
            signs.new_covered(bufname, 5),
            signs.new_partial(bufname, 6),
            signs.new_covered(bufname, 7),
            signs.new_uncovered(bufname, 9),
        }
        ---@diagnostic disable-next-line: unused-local
        for i, sign in ipairs(lines) do
            sign["buffer"] = nil
        end
        return lines
    end
    it("places signs", function()
        vim.api.nvim_set_current_dir("tests/languages/python/")
        vim.cmd("edit fizzbuzz.py")

        local coverage = require("coverage")
        coverage.load(true)
        local config = require("coverage.config")

        vim.wait(1000)
        local bufname = vim.fn.bufname()
        local placed = vim.fn.sign_getplaced(bufname, { group = config.opts.sign_group })
        assert.equal(1, #placed)
        local placed_signs = placed[1].signs
        ---@diagnostic disable-next-line: unused-local
        for i, sign in ipairs(placed_signs) do
            sign["id"] = nil
        end
        local expected = python_coverage(bufname)
        assert.are.same(#expected, #placed_signs)
        assert.are.same(expected[1], placed_signs[1])
        assert.are.same(expected[2], placed_signs[2])
        assert.are.same(expected[3], placed_signs[3])
        assert.are.same(expected[4], placed_signs[4])
        assert.are.same(expected[5], placed_signs[5])
        assert.are.same(expected[6], placed_signs[6])
        assert.are.same(expected[7], placed_signs[7])
        assert.are.same(expected[8], placed_signs[8])
    end)
end)
