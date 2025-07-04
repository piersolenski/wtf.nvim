local config = require("wtf.config")
local curl = require("plenary.curl")
local get_api_key = require("wtf.util.get_api_key")
local hooks = require("wtf.hooks")

local DEFAULT_MAX_TOKENS = 4096

local function build_headers(headers, api_key)
  local processed_headers = {}
  for key, value in pairs(headers) do
    local processed_value = value:gsub("${api_key}", api_key or "")
    processed_headers[key] = processed_value
  end
  return processed_headers
end

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

local function client(provider, system, messages)
  hooks.run_started_hook()

  local target_provider = config.options.provider
  local model_id = config.options.providers[target_provider].model_id
  local custom_api_key = config.options.providers[target_provider].api_key

  local url = config.options.providers[target_provider].url or provider.url

  local api_key

  if custom_api_key or provider.api_key then
    api_key = get_api_key(custom_api_key or provider.api_key)
    if not api_key then
      return nil, "No API key found"
    end
  end

  local request_data = provider.format_request({
    model = model_id,
    max_tokens = DEFAULT_MAX_TOKENS,
    system = system,
    messages = messages,
  })

  local headers = build_headers(provider.headers, api_key)
  local response = make_http_request(url, headers, request_data)

  return process_response(response, provider)
end

return client
