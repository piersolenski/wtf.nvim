local plugin = require("wtf")

local buffer_number = 0
local line_with_error = 3

local set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

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

describe("Plugin", function()
  before_each(function()
    set_lines({
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
      "Line 5",
    })

    -- Create an error
    local namespace = vim.api.nvim_create_namespace("wtf")
    vim.diagnostic.set(namespace, buffer_number, {
      {
        bufnr = buffer_number,
        lnum = line_with_error - 1,
        end_lnum = 1,
        col = 0,
        end_col = 5,
        severity = vim.diagnostic.severity.ERROR,
        message = "Oh my god all the things are broken!",
      },
    })
    vim.api.nvim_win_set_cursor(0, { line_with_error, 0 })
  end)

  describe("Search", function()
    it("works with the default search engine", function()
      plugin.setup()

      -- Mock the vim.fn.system function
      local original_fn = vim.fn.system
      vim.fn.system = function(_)
        return "Test output"
      end

      local result = plugin.search()
      assert.is.equal(result, "Test output")
      vim.fn.system = original_fn
    end)

    it("breaks with an unsupported engine", function()
      local result = plugin.search("ask_jeeves")
      assert.are.equal("Invalid search engine", result)
    end)

    it("breaks when no diagnostics are found", function()
      vim.api.nvim_win_set_cursor(0, { line_with_error + 1, 0 })
      local result = plugin.search()
      assert.are.equal("No diagnostics found!", result)
    end)
  end)

  describe("AI", function()
    it("breaks when no diagnostics are found", function()
      vim.api.nvim_win_set_cursor(0, { line_with_error + 1, 0 })

      local result = plugin.ai()
      assert.are.equal("No diagnostics found!", result)
    end)

    it("works when line diagnostics are found", function()
      local result = plugin.ai()
      local valid_job_identifier = 3
      assert.are.equal(valid_job_identifier, result)
    end)

    it("ai works when range diagnostics are found", function()
      local result = plugin.ai({ line1 = line_with_error - 1, line2 = line_with_error + 2 })
      local valid_job_identifier = 4 -- TODO: Fix race condition, should be 3
      assert.are.equal(valid_job_identifier, result)
    end)

    it("get status returns a string", function()
      local result = plugin.get_status()
      assert.are.equal("string", type(result))
    end)
  end)
end)

describe("Get Status", function()
  it("returns a string", function()
    local result = plugin.get_status()
    assert.are.equal("string", type(result))
  end)
end)
