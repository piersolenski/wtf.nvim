---@module 'luassert'

local plugin = require("wtf")

describe("Setup", function()
  it("accepts valid config", function()
    plugin.setup({
      context = false,
    })
  end)

  it("rejects a broken config", function()
    assert.error_matches(function()
      plugin.setup({
        context = "bananas",
      })
    end, "expected boolean, got string")
  end)
end)

describe("Get Status", function()
  it("returns a string", function()
    local result = plugin.get_status()
    assert.are.equal("string", type(result))
  end)
end)
