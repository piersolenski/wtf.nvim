local hooks = require("wtf.hooks")
local get_api_key = require("wtf.utils.get_api_key")
local config = require("wtf.config")
local providers = require("wtf.providers")
local curl = require("plenary.curl")

local DEFAULT_MAX_TOKENS = 4096

local function get_provider_config(provider_name)
  local provider_config = providers[provider_name]
  if not provider_config then
    error("Provider '" .. provider_name .. "' not found in available providers")
  end
  return provider_config
end

local function build_headers(headers, api_key)
  local processed_headers = {}
  for key, value in pairs(headers) do
    local processed_value = value:gsub("${api_key}", api_key)
    processed_headers[key] = processed_value
  end
  return processed_headers
end

local function process_response(response, provider_config, callback)
  local success, response_table = pcall(vim.json.decode, response.body)

  if not success or not response_table then
    return vim.notify("Bad or no response from API", vim.log.levels.ERROR)
  end

  if response.status >= 400 then
    local error = provider_config.format_error(response_table)
    return vim.notify(error, vim.log.levels.ERROR)
  end

  local text = provider_config.format_response(response_table)

  if text then
    return callback(text)
  else
    vim.notify("Unexpected response format", vim.log.levels.ERROR)
  end
end

local function request_provider(system, payload, callback)
  hooks.run_started_hook()

  local selected_provider = config.options.provider
  local provider_config = get_provider_config(selected_provider)
  local model_id = config.options.providers[selected_provider].model_id
  local setup_api_key = config.options.providers[selected_provider].api_key

  local url = config.options.providers[selected_provider].url or provider_config.url

  local api_key = get_api_key(selected_provider, setup_api_key, provider_config.env.api_key)

  if not api_key then
    return nil
  end

  local request_data = provider_config.format_request({
    model = model_id,
    max_tokens = DEFAULT_MAX_TOKENS,
    system = system,
    payload = payload,
  })

  local headers = build_headers(provider_config.headers, api_key)

  curl.post(url, {
    headers = headers,
    body = vim.json.encode(request_data),
    callback = function(response)
      vim.schedule(function()
        process_response(response, provider_config, callback)
        hooks.run_finished_hook()
      end)
    end,
  })

  return true
end

return request_provider
