local plugin = require("wtf")
local save_chat = require("wtf.util.save_chat")

local buffer_number = 0
local line_with_error = 3
local namespace

local set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local create_errors = function(diagnostics)
  local diag_table = {}
  namespace = vim.api.nvim_create_namespace("wtf")

  for _, d in ipairs(diagnostics) do
    table.insert(diag_table, {
      bufnr = buffer_number,
      lnum = d.line - 1,
      end_lnum = d.line - 1,
      col = 0,
      end_col = 5,
      severity = vim.diagnostic.severity.ERROR,
      message = d.message,
    })
    vim.api.nvim_win_set_cursor(0, { d.line, 0 })
  end

  vim.diagnostic.set(namespace, buffer_number, diag_table)

  return diag_table
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
    -- Mock vim.notify to ignore notifications in test output
    vim.notify = function(msg, level)
      -- You can capture calls here if needed
    end

    set_lines({
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
      "Line 5",
    })
    create_errors({ {
      line = line_with_error,
      message = "Oh my god all the things are broken!",
    } })
    plugin.setup()
  end)

  describe("Search", function()
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
      local errors = create_errors({
        {
          line = line_with_error,
          message = "First diagnostic",
        },
        {
          line = line_with_error,
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
      vim.api.nvim_win_set_cursor(0, { line_with_error + 1, 0 })
      local result = plugin.search()
      assert.are.equal("No diagnostics found!", result)
    end)
  end)

  describe("diagnose", function()
    it("breaks when no diagnostics are found", function()
      vim.api.nvim_win_set_cursor(0, { line_with_error + 1, 0 })

      local result = plugin.diagnose()
      assert.are.equal("No diagnostics found!", result)
    end)

    it("works when line diagnostics are found", function()
      local result = plugin.diagnose()
      assert.are.equal(true, result)
    end)

    it("ai works when range diagnostics are found", function()
      local result = plugin.diagnose({ line1 = line_with_error - 1, line2 = line_with_error + 2 })
      assert.are.equal(true, result)
    end)
  end)
end)

describe("Get Status", function()
  it("returns a string", function()
    local result = plugin.get_status()
    assert.are.equal("string", type(result))
  end)
end)

describe("Quickfix", function()
  local chat_dir = "/tmp/wtf/chats"

  before_each(function()
    plugin.setup({
      chat_dir = chat_dir,
    })
  end)

  after_each(function()
    vim.fn.system("rm -rf " .. chat_dir)
  end)

  it("is empty by default", function()
    plugin.history()
    local quickfix_list = vim.fn.getqflist()

    assert.are.equal(0, #quickfix_list)
  end)

  it("has one item after a chat has been saved", function()
    save_chat("An example of a chat response")

    plugin.history()
    local quickfix_list = vim.fn.getqflist()

    assert.are.equal(1, #quickfix_list)
  end)
end)
