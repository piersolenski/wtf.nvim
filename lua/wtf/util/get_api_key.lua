local function get_api_key(api_key)
  if type(api_key) == "function" then
    return api_key()
  elseif type(api_key) == "string" then
    return api_key
  else
    error("api_key must be a string or function, got " .. type(api_key))
  end
end

return get_api_key
