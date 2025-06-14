local hooks = require("wtf.hooks")
local config = require("wtf.config")
local anthropic = require("wtf.providers.anthropic")
local openai = require("wtf.providers.openai")

local providers = {
  anthropic = anthropic,
  openai = openai,
}

local M = {}

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

local function build_curl_command(url, headers, api_key, temp_file_path)
  local header_args = {}

  for key, value in pairs(headers) do
    -- Replace placeholder with actual api_key value
    local processed_value = value:gsub("${api_key}", api_key)
    table.insert(header_args, '-H "' .. key .. ": " .. processed_value .. '"')
  end

  -- Detect operating system using Neovim's built-in functions
  local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local cleanup_cmd = is_windows and "del" or "rm"
  local null_device = is_windows and "nul" or "/dev/null"

  return "curl -s "
    .. url
    .. " "
    .. table.concat(header_args, " ")
    .. ' --data-binary "@'
    .. temp_file_path
    .. '"'
    .. "; "
    .. cleanup_cmd
    .. " "
    .. temp_file_path
    .. " > "
    .. null_device
    .. " 2>&1"
end

function M.request(system, payload, callback)
  hooks.run_started_hook()
  local selected_provider = config.options.provider
  local model_id = config.options.providers[selected_provider].model_id
  local setup_api_key = config.options.providers[selected_provider].api_key
  local provider_config = providers[selected_provider]

  if not provider_config then
    error("Provider '" .. selected_provider .. "' not found in available providers")
  end

  local messages = {
    {
      role = "system",
      content = system,
    },
    {
      role = "user",
      content = payload,
    },
  }

  local api_key = get_api_key(selected_provider, setup_api_key, provider_config.env.api_key)

  if api_key == nil then
    return nil
  end

  -- Check if curl is installed
  if vim.fn.executable("curl") == 0 then
    vim.fn.confirm("curl installation not found. Please install curl to use Wtf", "&OK", 1, "Warning")

    return nil
  end

  local curlRequest

  -- Create temp file
  local tempFilePath = vim.fn.tempname()
  local tempFile = io.open(tempFilePath, "w")
  if tempFile == nil then
    vim.notify("Error creating temp file", vim.log.levels.ERROR)
    return nil
  end

  -- Write dataJSON to temp file
  local dataJSON = vim.json.encode({
    model = model_id,
    messages = messages,
  })
  tempFile:write(dataJSON)
  tempFile:close()

  -- Escape the name of the temp file for command line
  local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)

  local curl_request = build_curl_command(provider_config.url, provider_config.headers, api_key, tempFilePathEscaped)

  return vim.fn.jobstart(curl_request, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      local response = table.concat(data, "\n")
      local success, responseTable = pcall(vim.json.decode, response)

      if success == false or responseTable == nil then
        if responseTable == nil then
          responseTable = "nil"
        end
        vim.notify("Bad or no responseTable: ", vim.log.levels.ERROR)

        hooks.run_finished_hook()
        return nil
      end

      if responseTable.error ~= nil then
        vim.notify("Error: " .. responseTable.error.message, vim.log.levels.ERROR)

        hooks.run_finished_hook()
        return nil
      end

      local text = provider_config.format_response(responseTable)

      if text then
        callback(text)
      else
        vim.notify("Unexpected response format", vim.log.levels.ERROR)
      end

      hooks.run_finished_hook()
    end,
    on_stderr = function(_, data, _)
      return data
    end,
    on_exit = function(_, data, _)
      return data
    end,
  })
end

return M
