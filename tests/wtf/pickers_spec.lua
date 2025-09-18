local wtf = require("wtf")

describe("Picker functionality", function()
  it("Should have default picker set to telescope", function()
    wtf.setup({})
    local config = require("wtf.config")
    assert.are.equal("telescope", config.options.picker)
  end)

  it("Should accept valid picker configurations", function()
    local valid_pickers = { "telescope", "snacks", "fzf-lua" }
    for _, picker in ipairs(valid_pickers) do
      local ok = pcall(wtf.setup, { picker = picker })
      assert.is_true(ok, "Failed to set picker to " .. picker)
    end
  end)

  it("Should reject invalid picker configurations", function()
    local ok = pcall(wtf.setup, { picker = "invalid-picker" })
    assert.is_false(ok)
  end)

  it("Should load picker modules without error", function()
    local pickers = require("wtf.pickers")
    assert.is_not_nil(pickers)
    assert.is_function(pickers.get_picker)
    assert.is_function(pickers.grep_history)
  end)

  it("Should handle missing picker plugins gracefully", function()
    -- Set up a picker that might not be available
    wtf.setup({ picker = "snacks" })
    local pickers = require("wtf.pickers")

    -- This should not error even if snacks is not available
    -- The function should handle fallback or error gracefully
    local ok = pcall(pickers.get_picker)
    assert.is_true(ok)
  end)
end)