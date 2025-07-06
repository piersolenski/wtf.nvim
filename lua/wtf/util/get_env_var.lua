local function get_env_var(env_var)
  local value = os.getenv(env_var)

  if not value then
    error("Missing environment variable: " .. env_var)
  end

  return value
end

return get_env_var
