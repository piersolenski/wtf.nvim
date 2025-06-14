local function get_api_key(provider, setup_api_key, env_api_key)
  if setup_api_key ~= nil then
    return setup_api_key
  end

  local key = os.getenv(env_api_key)
  if key ~= nil then
    return key
  end

  local message = "No API key found for "
    .. provider
    .. ". Please set api_key in the setup table or set the $"
    .. env_api_key
    .. " environment variable."
  vim.fn.confirm(message, "&OK", 1, "Error")
  return nil
end

return get_api_key
