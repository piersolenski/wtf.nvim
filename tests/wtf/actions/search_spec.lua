local plugin = require("wtf")
local helpers = require("tests.wtf.helpers")

describe("Search", function()
  before_each(function()
    helpers.disable_notifications()

    helpers.create_lines({
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
      "Line 5",
    })

    helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "Oh my god all the things are broken!",
      },
    })
    plugin.setup()
  end)

  it("works with the default search engine", function()
    -- Mock the vim.fn.system function
    local original_fn = vim.fn.system
    vim.fn.system = function(_)
      return "Test output"
    end

    local result = plugin.search()
    assert.is.equal(result, "Test output")
    vim.fn.system = original_fn
  end)

  it("handles multiple errors on the same line", function()
    local errors = helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "First diagnostic",
      },
      {
        line = helpers.line_with_error,
        message = "Second diagnostic",
      },
    })

    local second_error = errors[2]

    -- Mock vim.ui.select
    local original_select = vim.ui.select
    vim.ui.select = function(_, _, on_choice)
      -- Simulate selecting the second option
      on_choice(second_error)
    end

    -- Mock the vim.fn.system function
    local original_fn = vim.fn.system
    vim.fn.system = function(_)
      return second_error.message
    end

    -- Use a coroutine to handle the asynchronous behavior of vim.ui.select
    local co = coroutine.create(function()
      local result = plugin.search()
      assert.is.equal(result, second_error.message)
    end)

    -- Run the coroutine
    coroutine.resume(co)

    -- Restore original functions
    vim.fn.system = original_fn
    vim.ui.select = original_select
  end)

  it("breaks with an unsupported engine", function()
    local result, error = plugin.search("ask_jeeves")
    assert.is_nil(result)
    assert.equals("Invalid search engine", error)
  end)

  it("breaks when no diagnostics are found", function()
    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error + 1, 0 })
    local result = plugin.search()
    assert.are.equal("No diagnostics found!", result)
  end)
end)
