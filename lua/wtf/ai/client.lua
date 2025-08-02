local config = require("wtf.config")
local curl = require("plenary.curl")
local get_api_key = require("wtf.util.get_api_key")
local get_provider = require("wtf.util.get_provider")

local DEFAULT_MAX_TOKENS = 4096

--- Processes headers by replacing ${api_key} placeholders with the actual API key
---@param headers table<string, string>
---@param api_key string?
---@return table<string, string>
local function build_headers(headers, api_key)
  local processed_headers = {}
  for key, value in pairs(headers) do
    local processed_value = value:gsub("${api_key}", api_key or "")
    processed_headers[key] = processed_value
  end
  return processed_headers
end

--- Processes HTTP response from AI provider API
---@param response table
---@param provider_config table
---@return string? text
---@return string? error
local function process_response(response, provider_config)
  local success, response_table = pcall(vim.json.decode, response.body)

  if not success or not response_table then
    return nil, "Bad or no response from API"
  end

  if response.status >= 400 then
    local error = provider_config.format_error(response_table)
    return nil, error
  end

  local text = provider_config.format_response(response_table)

  if text then
    return text, nil
  else
    return nil, "Unexpected response format"
  end
end

--- Makes asynchronous HTTP POST request using coroutines
---@param url string
---@param headers table<string, string>
---@param request_data table
---@return table HTTP
local function make_http_request(url, headers, request_data)
  local co = coroutine.running()

  curl.post(url, {
    headers = headers,
    body = vim.json.encode(request_data),
    callback = function(response)
      vim.schedule(function()
        coroutine.resume(co, response)
      end)
    end,
  })

  return coroutine.yield()
end

--- Main client function that sends message to AI provider and returns response
---@param system string
---@param message string
---@return string? text
---@return string? error
local function client(system, message)
  local provider_id = config.options.provider
  local provider = config.options.providers[provider_id]

  if not provider then
    return nil, string.format("Provider '%s' not found in configuration", provider_id or "nil")
  end

  local model_id = provider.model_id
  local api_key = provider.api_key

  if api_key then
    local success, result = pcall(get_api_key, api_key)
    if not success then
      return nil, result
    end
    api_key = result
  end

  local request_data = provider.format_request({
    model = model_id,
    max_tokens = DEFAULT_MAX_TOKENS,
    system = system,
    message = message,
  })

  local headers = build_headers(provider.headers, api_key)
  local response = make_http_request(provider.url, headers, request_data)

  return process_response(response, provider)
end

return client
