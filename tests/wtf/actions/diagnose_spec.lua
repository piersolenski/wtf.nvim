local helpers = require("tests.wtf.helpers")
local mock = require("luassert.mock")
local spy = require("luassert.spy")
local wtf = require("wtf")

describe("Diagnose", function()
  local client_mock
  local popup_mock

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
    popup_mock = mock(require("wtf.ui.popup"), true)

    wtf.setup()
  end)

  after_each(function()
    mock.revert(client_mock)
    mock.revert(popup_mock)
  end)

  it("exits when no diagnostics are found", function()
    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error + 1, 0 })
    local result = wtf.diagnose()
    assert.are.equal("No diagnostics found!", result)
  end)

  it("works when line diagnostics are found", function(done)
    local popup_spy = spy.on(popup_mock, "show")
    wtf.diagnose()
    vim.defer_fn(function()
      assert.spy(client_mock).was.called()
      assert.spy(popup_spy).was.called_with("This is a test response")
      done()
    end, 100)
  end)

  it("works when range diagnostics are found", function(done)
    local popup_spy = spy.on(popup_mock, "show")
    wtf.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 1 })
    vim.defer_fn(function()
      assert.spy(client_mock).was.called()
      local payload = client_mock.calls[1].args[2]
      assert.truthy(string.find(payload, "Line 2"))
      assert.truthy(string.find(payload, "Line 3"))
      assert.truthy(string.find(payload, "Line 4"))
      assert.spy(popup_spy).was.called_with("This is a test response")
      done()
    end, 100)
  end)
end)
