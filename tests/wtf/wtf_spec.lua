---@module 'luassert'

local wtf = require("wtf")

describe("Setup", function()
  it("accepts valid config", function()
    wtf.setup({
      popup_type = "popup",
    })
  end)

  it("rejects a broken config", function()
    assert.error_matches(function()
      wtf.setup({
        popup_type = "bananas",
      })
    end, "popup_type: expected supported popup type, got bananas")
  end)
end)

describe("Get Status", function()
  it("returns a string", function()
    local result = wtf.get_status()
    assert.are.equal("string", type(result))
  end)
end)

describe("Pick Provider", function()
  it("updates the provider when one is selected", function()
    -- Mock vim.ui.select
    local original_vim_ui_select = vim.ui.select
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(_, _, on_choice)
      -- Simulate selecting "gemini"
      on_choice("gemini")
    end

    -- Mock vim.notify
    local notify_message
    local original_vim_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg)
      notify_message = msg
    end

    local config = require("wtf.config")
    -- Set initial provider
    config.options.provider = "openai"

    wtf.pick_provider()

    -- Assert that the provider was updated
    assert.are.equal("gemini", config.options.provider)
    assert.are.equal("Provider set to: gemini", notify_message)

    -- Restore original functions
    vim.ui.select = original_vim_ui_select
    vim.notify = original_vim_notify
  end)
end)
