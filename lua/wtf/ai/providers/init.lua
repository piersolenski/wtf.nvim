---@class Wtf.Adapter
---@field name string The name of the adapter e.g. "openai"
---@field formatted_name string The formatted name of the adapter e.g. "OpenAI"
---@field url string The base URL of the LLM API
---@field headers table<string, string> The headers to pass to the request
---@field api_key string | fun(): string | nil | nil Retrieve API key
---@field format_request fun(data: table): table Function to format request data
---@field format_response fun(response: table): string Function to format API response
---@field format_error fun(response: table): string Function to format error response

local M = {}

-- Import all provider modules
M.anthropic = require("wtf.ai.providers.anthropic")
-- M.copilot = require("wtf.ai.providers.copilot")
M.deepseek = require("wtf.ai.providers.deepseek")
M.gemini = require("wtf.ai.providers.gemini")
M.grok = require("wtf.ai.providers.grok")
M.ollama = require("wtf.ai.providers.ollama")
M.openai = require("wtf.ai.providers.openai")

-- Helper function to get just the names
function M.get_names()
  local names = {}
  for _, provider in pairs(M) do
    if type(provider) == "table" and provider.name then
      table.insert(names, provider.name)
    end
  end
  return names
end

return M
