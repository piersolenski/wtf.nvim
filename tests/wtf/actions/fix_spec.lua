local helpers = require("tests.wtf.helpers")
local mock = require("luassert.mock")
local wtf = require("wtf")

describe("Fix", function()
  local client_mock

  before_each(function()
    helpers.disable_notifications()

    helpers.create_lines({
      "Line 1",
      "Line 2",
      "Line 3", -- helpers.line_with_error
      "Line 4",
      "Line 5",
    })

    helpers.create_errors({
      {
        line = helpers.line_with_error,
        message = "Oh my god all the things are broken!",
      },
    })

    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error, 0 })

    -- Mock dependencies
    client_mock = mock(require("wtf.ai.client"), true)
    client_mock.returns("This is a test response")

    wtf.setup()
  end)

  it("fixes when there are diagnostics", function(done)
    wtf.fix({})

    -- Then
    vim.defer_fn(function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ "print(vim.version())" }, lines)

      -- Cleanup
      mock.revert(client_mock)
      done()
    end, 100)
  end)

  it("exits when no diagnostics are found", function()
    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error + 1, 0 })
    local result = wtf.diagnose()
    assert.are.equal("No diagnostics found!", result)
  end)
end)
