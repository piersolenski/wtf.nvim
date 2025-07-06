local config = require("wtf.config")
local providers = require("wtf.ai.providers")

local function pick_provider()
  local provider_names = {}
  for name, _ in pairs(providers) do
    table.insert(provider_names, name)
  end
  table.sort(provider_names)

  vim.ui.select(provider_names, {
    prompt = "Select a provider:",
  }, function(choice)
    if choice then
      config.options.provider = choice
      vim.notify("Provider set to: " .. choice)
    end
  end)
end

return pick_provider
