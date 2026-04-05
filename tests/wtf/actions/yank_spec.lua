---@module 'luassert'

local helpers = require("tests.wtf.helpers")
local plugin = require("wtf")

describe("Yank", function()
  before_each(function()
    helpers.disable_notifications()

    helpers.create_lines({
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
      "Line 5",
    })

    plugin.setup()
  end)

  it("yanks a single diagnostic to clipboard", function()
    helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "Something went wrong",
      },
    })

    plugin.yank()

    local yanked = vim.fn.getreg("+")
    assert.is_not_nil(yanked)
    assert.is_truthy(yanked:find("Something went wrong"))
    assert.is_truthy(yanked:find("%[ERROR%]"))
    -- Also in unnamed register
    assert.are.equal(yanked, vim.fn.getreg('"'))
  end)

  it("yanks multiple diagnostics on the same line", function()
    helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "First diagnostic",
      },
      {
        line = helpers.line_with_error,
        message = "Second diagnostic",
      },
    })

    plugin.yank()

    local yanked = vim.fn.getreg("+")
    assert.is_truthy(yanked:find("First diagnostic"))
    assert.is_truthy(yanked:find("Second diagnostic"))
    -- Both should be present, separated by newline
    assert.is_truthy(yanked:find("\n"))
  end)

  it("returns nil and warns when no diagnostics found", function()
    -- Move cursor to a line with no errors
    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error + 1, 0 })

    local notified = false
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN and msg:find("No diagnostics") then
        notified = true
      end
    end

    local result = plugin.yank()
    assert.is_nil(result)
    assert.is_true(notified)
  end)

  it("yanks diagnostics across a range of lines", function()
    helpers.create_errors({
      {
        line = 2,
        message = "Error on line 2",
      },
      {
        line = 4,
        message = "Error on line 4",
      },
    })

    plugin.yank({ line1 = 2, line2 = 4 })

    local yanked = vim.fn.getreg("+")
    assert.is_truthy(yanked:find("Error on line 2"))
    assert.is_truthy(yanked:find("Error on line 4"))
  end)

  it("includes location info in formatted output", function()
    helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "Type mismatch",
      },
    })

    plugin.yank()

    local yanked = vim.fn.getreg("+")
    -- Should contain line and column references
    assert.is_truthy(yanked:find(":L%d+:C%d+"))
  end)
end)
