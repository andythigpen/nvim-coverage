local signs = require("coverage.signs")

describe("languages.go", function()
    local go_coverage = function(bufname)
        local lines = {
            signs.new_covered(bufname, 5),
            signs.new_covered(bufname, 6),
            signs.new_covered(bufname, 7),
            signs.new_covered(bufname, 8),
            signs.new_covered(bufname, 9),
            signs.new_covered(bufname, 10),
            signs.new_covered(bufname, 11),
            signs.new_covered(bufname, 12),
            signs.new_uncovered(bufname, 13),
            signs.new_uncovered(bufname, 14),
        }
        ---@diagnostic disable-next-line: unused-local
        for i, sign in ipairs(lines) do
            sign["buffer"] = nil
        end
        return lines
    end
    it("places signs", function()
        vim.api.nvim_set_current_dir("tests/languages/go/")
        vim.cmd("edit fizzbuzz.go")

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
        local expected = go_coverage(bufname)
        assert.are.same(#expected, #placed_signs)
        assert.are.same(expected[1], placed_signs[1])
        assert.are.same(expected[2], placed_signs[2])
        assert.are.same(expected[3], placed_signs[3])
        assert.are.same(expected[4], placed_signs[4])
        assert.are.same(expected[5], placed_signs[5])
        assert.are.same(expected[6], placed_signs[6])
        assert.are.same(expected[7], placed_signs[7])
        assert.are.same(expected[8], placed_signs[8])
        assert.are.same(expected[9], placed_signs[9])
        assert.are.same(expected[10], placed_signs[10])
    end)
end)
