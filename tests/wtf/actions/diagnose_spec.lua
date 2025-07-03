local plugin = require("wtf")
local helpers = require("tests.wtf.helpers")

describe("Diagnose", function()
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

  it("breaks when no diagnostics are found", function()
    vim.api.nvim_win_set_cursor(0, { helpers.line_with_error + 1, 0 })

    local result = plugin.diagnose()
    assert.are.equal("No diagnostics found!", result)
  end)

  it("works when line diagnostics are found", function()
    local result = plugin.diagnose()
    -- Write test
  end)

  it("ai works when range diagnostics are found", function()
    local result = plugin.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 2 })
    -- Write test
  end)

  it("works when an environment variable is set", function()
    -- Mock the environment variable existing
    vim.fn.setenv("OPENAI_API_KEY", "FAKE_KEY")

    plugin.setup({
      provider = "openai",
    })
    local result = plugin.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 2 })
    -- Write test
  end)

  it("fails when an environment variable is not set", function()
    -- Mock the environment variable not existing
    vim.fn.setenv("OPENAI_API_KEY", nil)

    plugin.setup({
      provider = "openai",
    })
    local result = plugin.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 2 })
    -- Write test
  end)

  it("accepts a custom api key as a string", function()
    plugin.setup({
      provider = "openai",
      providers = {
        openai = {
          api_key = "API_KEY",
        },
      },
    })
    local result = plugin.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 2 })
    -- Write test
  end)

  it("accepts a custom api key as a function", function()
    plugin.setup({
      provider = "openai",
      providers = {
        openai = {
          api_key = function()
            return "API_KEY"
          end,
        },
      },
    })
    local result = plugin.diagnose({ line1 = helpers.line_with_error - 1, line2 = helpers.line_with_error + 2 })
    -- Write test
  end)
end)
