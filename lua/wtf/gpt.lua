local config = require("wtf.config")

local M = {}

local callback_counter = 0

local status_index = 0
local progress_bar_dots = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function run_started_hook()
  local request_started = config.options.hooks and config.options.hooks.request_started
  if request_started ~= nil then
    request_started()
  end

  callback_counter = callback_counter + 1
end

local function run_finished_hook()
  callback_counter = callback_counter - 1
  if callback_counter <= 0 then
    local request_finished = config.options.hooks and config.options.hooks.request_finished
    if request_finished ~= nil then
      request_finished()
    end
  end
end

function M.get_status()
  if callback_counter > 0 then
    status_index = status_index + 1
    if status_index > #progress_bar_dots then
      status_index = 1
    end
    return progress_bar_dots[status_index]
  else
    return ""
  end
end

local function get_model_id()
  local model = config.options.openai_model_id
  if model == nil then
    if vim.g.wtf_model_id_complained == nil then
      local message =
        "No model id specified. Please set openai_model_id in the setup table. Defaulting to gpt-3.5-turbo for now"
      vim.fn.confirm(message, "&OK", 1, "Warning")
      vim.g.wtf_model_id_complained = 1
    end
    return "qwen2:7b"
  end
  return model
end

local function get_api_url()
  local api_url = config.options.openai_api_url
  if api_url == nil then
    local url = os.getenv("OPENAI_API_URL")
    if url ~= nil then
      return url
    else
      return "https://api.openai.com/v1/"
    end
    local message =
      "No API url found. Please set openai_api_url in the setup table or set the $OPENAI_API_URL environment variable."
    vim.fn.confirm(message, "&OK", 1, "Warning")
    return nil
  end
  return api_url
end

local function get_api_key()
  local api_key = config.options.openai_api_key
  if api_key == nil then
    local key = os.getenv("OPENAI_API_KEY")
    if key ~= nil then
      return key
    end
    local message =
      "No API key found. Please set openai_api_key in the setup table or set the $OPENAI_API_KEY environment variable."
    vim.fn.confirm(message, "&OK", 1, "Warning")
    return nil
  end
  return api_key
end

function M.request(messages, callback, callbackTable)
  local api_url = get_api_url()
  local api_key = get_api_key()

  if api_url == nil then
    return nil
  end
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
    model = get_model_id(),
    messages = messages,
  })
  tempFile:write(dataJSON)
  tempFile:close()

  -- Escape the name of the temp file for command line
  local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)

  -- Check if the user is on windows
  local isWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

  run_started_hook()

  if isWindows ~= true then
    -- Linux
    curlRequest = string.format(
      'curl -s "'
        .. api_url
        .. 'chat/completions"'
        .. ' -H "Content-Type: application/json" -H "Authorization: Bearer '
        .. api_key
        .. '" --data-binary "@'
        .. tempFilePathEscaped
        .. '"; rm '
        .. tempFilePathEscaped
        .. " > /dev/null 2>&1"
    )
  else
    -- Windows
    curlRequest = string.format(
      'curl -s "'
        .. api_url
        .. 'chat/completions"'
        .. ' -H "Content-Type: application/json" -H "Authorization: Bearer '
        .. api_key
        .. '" --data-binary "@'
        .. tempFilePathEscaped
        .. '" & del '
        .. tempFilePathEscaped
        .. " > nul 2>&1"
    )
  end

  return vim.fn.jobstart(curlRequest, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      local response = table.concat(data, "\n")
      local success, responseTable = pcall(vim.json.decode, response)

      if success == false or responseTable == nil then
        if response == nil then
          response = "nil"
        end
        vim.notify("Bad or no response: ", vim.log.levels.ERROR)

        run_finished_hook()
        return nil
      end

      if responseTable.error ~= nil then
        vim.notify("OpenAI Error: " .. responseTable.error.message, vim.log.levels.ERROR)

        run_finished_hook()
        return nil
      end

      callback(responseTable, callbackTable)
      run_finished_hook()
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
