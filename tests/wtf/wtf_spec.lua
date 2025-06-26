local plugin = require("wtf")
local save_chat = require("wtf.save_chat")
local providers = require("wtf.providers")

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
      local result = plugin.search("ask_jeeves")
      assert.are.equal("Invalid search engine", result)
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
      local valid_job_identifier = 3
      assert.are.equal(valid_job_identifier, result)
    end)

    it("ai works when range diagnostics are found", function()
      local result = plugin.diagnose({ line1 = line_with_error - 1, line2 = line_with_error + 2 })
      local valid_job_identifier = 4
      assert.are.equal(valid_job_identifier, result)
    end)
  end)
end)

describe("Get Status", function()
  it("returns a string", function()
    local result = plugin.get_status()
    assert.are.equal("string", type(result))
  end)
end)

describe("Providers", function()
  describe("Provider Loading", function()
    it("loads all expected providers", function()
      assert.is_not.Nil(providers.openai)
      assert.is_not.Nil(providers.anthropic)
      assert.is_not.Nil(providers.grok)
    end)

    it("get_names returns all provider names", function()
      local names = providers.get_names()
      assert.is.truthy(vim.tbl_contains(names, "openai"))
      assert.is.truthy(vim.tbl_contains(names, "anthropic"))
      assert.is.truthy(vim.tbl_contains(names, "grok"))
    end)
  end)

  describe("OpenAI Provider", function()
    local openai = providers.openai

    it("has correct configuration", function()
      assert.are.equal("openai", openai.name)
      assert.are.equal("OpenAI", openai.formatted_name)
      assert.are.equal("https://api.openai.com/v1", openai.base_url)
      assert.are.equal("/chat/completions", openai.endpoint)
      assert.are.equal("OPENAI_API_KEY", openai.env.api_key)
    end)

    it("has required headers", function()
      assert.are.equal("application/json", openai.headers["Content-Type"])
      assert.are.equal("Bearer ${api_key}", openai.headers.Authorization)
    end)

    it("formats request data correctly", function()
      local test_data = {
        model = "gpt-4",
        system = "You are a helpful assistant",
        payload = "What is 2+2?",
      }
      
      local formatted = openai.format_request(test_data)
      
      assert.are.equal("gpt-4", formatted.model)
      assert.are.equal(2, #formatted.messages)
      assert.are.equal("system", formatted.messages[1].role)
      assert.are.equal("You are a helpful assistant", formatted.messages[1].content)
      assert.are.equal("user", formatted.messages[2].role)
      assert.are.equal("What is 2+2?", formatted.messages[2].content)
    end)

    it("formats response correctly", function()
      local test_response = {
        choices = {
          {
            message = {
              content = "2+2 equals 4"
            }
          }
        }
      }
      
      local formatted = openai.format_response(test_response)
      assert.are.equal("2+2 equals 4", formatted)
    end)

    it("formats error correctly", function()
      local test_error = {
        error = {
          message = "Invalid API key"
        }
      }
      
      local formatted = openai.format_error(test_error)
      assert.are.equal("Invalid API key", formatted)
    end)
  end)

  describe("Anthropic Provider", function()
    local anthropic = providers.anthropic

    it("has correct configuration", function()
      assert.are.equal("anthropic", anthropic.name)
      assert.are.equal("Anthropic", anthropic.formatted_name)
      assert.are.equal("https://api.anthropic.com/v1", anthropic.base_url)
      assert.are.equal("/messages", anthropic.endpoint)
      assert.are.equal("ANTHROPIC_API_KEY", anthropic.env.api_key)
    end)

    it("has required headers", function()
      assert.are.equal("application/json", anthropic.headers["content-type"])
      assert.are.equal("${api_key}", anthropic.headers["x-api-key"])
      assert.are.equal("2023-06-01", anthropic.headers["anthropic-version"])
    end)

    it("formats request data correctly", function()
      local test_data = {
        model = "claude-3-sonnet-20240229",
        max_tokens = 1000,
        system = "You are a helpful assistant",
        payload = "What is 2+2?",
      }
      
      local formatted = anthropic.format_request(test_data)
      
      assert.are.equal("claude-3-sonnet-20240229", formatted.model)
      assert.are.equal(1000, formatted.max_tokens)
      assert.are.equal("You are a helpful assistant", formatted.system)
      assert.are.equal(1, #formatted.messages)
      assert.are.equal("user", formatted.messages[1].role)
      assert.are.equal("What is 2+2?", formatted.messages[1].content)
    end)

    it("formats response correctly", function()
      local test_response = {
        content = {
          {
            text = "2+2 equals 4"
          }
        }
      }
      
      local formatted = anthropic.format_response(test_response)
      assert.are.equal("2+2 equals 4", formatted)
    end)

    it("formats error correctly", function()
      local test_error = {
        error = {
          message = "Invalid API key"
        }
      }
      
      local formatted = anthropic.format_error(test_error)
      assert.are.equal("Invalid API key", formatted)
    end)
  end)

  describe("Grok Provider", function()
    local grok = providers.grok

    it("has correct configuration", function()
      assert.are.equal("grok", grok.name)
      assert.are.equal("Grok", grok.formatted_name)
      assert.are.equal("https://api.x.ai/v1", grok.base_url)
      assert.are.equal("/chat/completions", grok.endpoint)
      assert.are.equal("XAI_API_KEY", grok.env.api_key)
    end)

    it("has required headers", function()
      assert.are.equal("application/json", grok.headers["Content-Type"])
      assert.are.equal("Bearer ${api_key}", grok.headers.Authorization)
    end)

    it("formats request data correctly", function()
      local test_data = {
        model = "grok-beta",
        max_tokens = 1000,
        system = "You are a helpful assistant",
        payload = "What is 2+2?",
      }
      
      local formatted = grok.format_request(test_data)
      
      assert.are.equal("grok-beta", formatted.model)
      assert.are.equal(1000, formatted.max_tokens)
      assert.are.equal(false, formatted.stream)
      assert.are.equal(0.7, formatted.temperature)
      assert.are.equal(2, #formatted.messages)
      assert.are.equal("system", formatted.messages[1].role)
      assert.are.equal("You are a helpful assistant", formatted.messages[1].content)
      assert.are.equal("user", formatted.messages[2].role)
      assert.are.equal("What is 2+2?", formatted.messages[2].content)
    end)

    it("formats response correctly", function()
      local test_response = {
        choices = {
          {
            message = {
              content = "2+2 equals 4"
            }
          }
        }
      }
      
      local formatted = grok.format_response(test_response)
      assert.are.equal("2+2 equals 4", formatted)
    end)

    it("formats error correctly", function()
      local test_error = {
        error = "Invalid API key"
      }
      
      local formatted = grok.format_error(test_error)
      assert.are.equal("Invalid API key", formatted)
    end)
  end)

  describe("Provider Functions", function()
    it("all providers have required functions", function()
      local required_functions = {
        "format_request",
        "format_response", 
        "format_error"
      }
      
      for provider_name, provider in pairs(providers) do
        if type(provider) == "table" and provider.name then
          for _, func_name in ipairs(required_functions) do
            assert.are.equal("function", type(provider[func_name]), 
              provider_name .. " missing " .. func_name .. " function")
          end
        end
      end
    end)

    it("all providers have required configuration fields", function()
      local required_fields = {
        "name",
        "formatted_name",
        "base_url",
        "endpoint",
        "headers",
        "env"
      }
      
      for provider_name, provider in pairs(providers) do
        if type(provider) == "table" and provider.name then
          for _, field_name in ipairs(required_fields) do
            assert.is_not.Nil(provider[field_name], 
              provider_name .. " missing " .. field_name .. " field")
          end
        end
      end
    end)
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
