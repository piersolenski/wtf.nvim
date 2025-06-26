local M = {}

-- Import all provider modules
M.anthropic = require("wtf.providers.anthropic")
M.gemini = require("wtf.providers.gemini")
M.grok = require("wtf.providers.grok")
M.openai = require("wtf.providers.openai")

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
