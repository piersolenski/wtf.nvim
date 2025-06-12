local M = {}

local config = {}
local callback_counter = 0
local status_index = 0
local progress_bar_dots = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

function M.setup(cfg)
  config = cfg or {}
end

local function run_started_hook()
  if config.hooks and config.hooks.request_started then
    config.hooks.request_started()
  end
  callback_counter = callback_counter + 1
end

local function run_finished_hook()
  callback_counter = callback_counter - 1
  if callback_counter <= 0 then
    if config.hooks and config.hooks.request_finished then
      config.hooks.request_finished()
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
  return config.modelId or "gpt-3.5-turbo"
end

local function get_api_key()
  return config.apiKey or os.getenv("OPENAI_API_KEY")
end

local function get_base_url()
  return config.baseUrl or "https://api.openai.com"
end

function M.request(messages, callback, callbackTable)
  local api_key = get_api_key()
  if not api_key then
    vim.fn.confirm("No API key found. Set via provider config or $OPENAI_API_KEY", "&OK", 1, "Warning")
    return nil
  end

  if vim.fn.executable("curl") == 0 then
    vim.fn.confirm("curl not found. Please install curl to use WTF", "&OK", 1, "Warning")
    return nil
  end

  local dataJSON = vim.json.encode({
    model = get_model_id(),
    messages = messages,
  })

  local tempFilePath = vim.fn.tempname()
  local tempFile = io.open(tempFilePath, "w")
  if not tempFile then
    vim.notify("Error creating temp file", vim.log.levels.ERROR)
    return nil
  end
  tempFile:write(dataJSON)
  tempFile:close()

  local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)
  local isWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

  run_started_hook()

  local curl_cmd
  if not isWindows then
    curl_cmd = string.format(
      'curl -s "%s/v1/chat/completions" -H "Content-Type: application/json" -H "Authorization: Bearer %s" --data-binary "@%s"; rm %s > /dev/null 2>&1',
      get_base_url(),
      api_key,
      tempFilePathEscaped,
      tempFilePathEscaped
    )
  else
    curl_cmd = string.format(
      'curl -s "%s/v1/chat/completions" -H "Content-Type: application/json" -H "Authorization: Bearer %s" --data-binary "@%s" & del %s > nul 2>&1',
      get_base_url(),
      api_key,
      tempFilePathEscaped,
      tempFilePathEscaped
    )
  end

  return vim.fn.jobstart(curl_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      local response = table.concat(data, "\n")
      local success, responseTable = pcall(vim.json.decode, response)

      if not success or not responseTable then
        vim.notify("Bad or no response", vim.log.levels.ERROR)
        run_finished_hook()
        return nil
      end

      if responseTable.error then
        vim.notify("OpenAI Error: " .. responseTable.error.message, vim.log.levels.ERROR)
        run_finished_hook()
        return nil
      end

      callback(responseTable, callbackTable)
      run_finished_hook()
    end,
    on_stderr = function(_, data, _) return data end,
    on_exit = function(_, data, _) return data end,
  })
end

return M
