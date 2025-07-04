local providers = require("wtf.ai.providers")

local function get_provider(provider_name)
  local provider_config = providers[provider_name]
  if not provider_config then
    error("Provider '" .. provider_name .. "' not found in available providers")
  end
  return provider_config
end

return get_provider
