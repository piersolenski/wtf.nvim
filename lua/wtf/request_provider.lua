local hooks = require("wtf.hooks")
local get_api_key = require("wtf.utils.get_api_key")
local config = require("wtf.config")
local providers = require("wtf.providers")

-- Constants
local DEFAULT_MAX_TOKENS = 4096

-- Helper functions
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end


local function get_cleanup_command()
  return is_windows() and "del" or "rm"
end

local function get_null_device()
  return is_windows() and "nul" or "/dev/null"
end

local function build_headers(headers, api_key)
  local header_args = {}
  for key, value in pairs(headers) do
    local processed_value = value:gsub("${api_key}", api_key)
    table.insert(header_args, '-H "' .. key .. ": " .. processed_value .. '"')
  end
  return table.concat(header_args, " ")
end

local function build_curl_command(data)
  local header_string = build_headers(data.headers, data.api_key)
  local cleanup_cmd = get_cleanup_command()
  local null_device = get_null_device()
  local url = data.base_url .. data.endpoint

  return string.format(
    'curl -s %s %s --data-binary "@%s"; %s %s > %s 2>&1',
    url,
    header_string,
    data.temp_file,
    cleanup_cmd,
    data.temp_file,
    null_device
  )
end

local function validate_dependencies()
  if vim.fn.executable("curl") == 0 then
    vim.fn.confirm("curl installation not found. Please install curl to use Wtf", "&OK", 1, "Error")
    return false
  end
  return true
end

local function validate_provider(provider_name)
  local provider_config = providers[provider_name]
  if not provider_config then
    error("Provider '" .. provider_name .. "' not found in available providers")
  end
  return provider_config
end

local function create_temp_file(data)
  local temp_file_path = vim.fn.tempname()
  local temp_file = io.open(temp_file_path, "w")

  if not temp_file then
    vim.notify("Error creating temp file", vim.log.levels.ERROR)
    return nil
  end

  temp_file:write(vim.json.encode(data))
  temp_file:close()

  return temp_file_path
end

local function handle_response_error(error_formatter, response)
  if response.error then
    vim.notify("Error: " .. error_formatter(response), vim.log.levels.ERROR)
    return true
  end
  return false
end

local function process_response(data, provider_config, callback)
  local response = table.concat(data, "\n")
  local success, response_table = pcall(vim.json.decode, response)

  if not success or not response_table then
    vim.notify("Bad or no response from API", vim.log.levels.ERROR)
    return
  end

  if handle_response_error(provider_config.format_error, response_table) then
    return
  end

  local text = provider_config.format_response(response_table)
  if text then
    callback(text)
  else
    vim.notify("Unexpected response format", vim.log.levels.ERROR)
  end
end

local function request_provider(system, payload, callback)
  hooks.run_started_hook()

  if not validate_dependencies() then
    return nil
  end

  local selected_provider = config.options.provider
  local provider_config = validate_provider(selected_provider)
  local model_id = config.options.providers[selected_provider].model_id
  local setup_api_key = config.options.providers[selected_provider].api_key
  local base_url = config.options.providers[selected_provider].base_url

  local api_key = get_api_key(selected_provider, setup_api_key, provider_config.env.api_key)

  if not api_key then
    return nil
  end

  local request_data = provider_config.format_request_data({
    model = model_id,
    max_tokens = DEFAULT_MAX_TOKENS,
    system = system,
    payload = payload,
  })

  local temp_file_path = create_temp_file(request_data)
  if not temp_file_path then
    return nil
  end

  local temp_file_path_escaped = vim.fn.fnameescape(temp_file_path)

  local curl_command = build_curl_command({
    base_url = base_url or provider_config.base_url,
    endpoint = provider_config.endpoint,
    headers = provider_config.headers,
    api_key = api_key,
    temp_file = temp_file_path_escaped,
  })

  return vim.fn.jobstart(curl_command, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      process_response(data, provider_config, callback)
    end,
    on_stderr = function(_, data, _)
      return data
    end,
    on_exit = function(_, data, _)
      hooks.run_finished_hook()
      return data
    end,
  })
end

return request_provider
