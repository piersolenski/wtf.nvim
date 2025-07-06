local client = require("wtf.ai.client")
local hooks = require("wtf.hooks")
local notify = require("wtf.util.notify")
local process_diagnostics = require("wtf.util.process_diagnostics")

local function handle_response(response, line1, line2)
  -- Clean the response by removing markdown code blocks if present
  local fixed_code = response:gsub("```[%w]*\n", ""):gsub("\n```", "")

  -- Remove carriage returns and then split the fixed code into lines
  local sanitized_code = fixed_code:gsub("\r", "")
  local fixed_lines = vim.split(sanitized_code, "\n")

  -- Replace the lines in the buffer
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, fixed_lines)

  vim.notify("Code fixed successfully!", vim.log.levels.INFO)
end

local function fix(opts)
  hooks.run_started_hook()

  local SYSTEM_PROMPT = "You are an expert coder fixing LSP "
    .. "diagnostic messages in code snippets as part of a Neovim "
    .. "plugin. The code you return should seamlessly replace "
    .. "the original code in the file, thus it should not "
    .. "contain line numbers, explanations or additional text. "
    .. "The snippet may be partial - do not add missing code "
    .. "the user didn't provide. Preserve all original "
    .. "formatting including tabs, spaces, and line breaks."

  local result = process_diagnostics(opts)
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return result.err
  end

  notify.ai_task_started("Fixing")

  -- Use coroutine since client function is async
  local co = coroutine.create(function()
    local response, client_err = client(SYSTEM_PROMPT, result.payload)

    if client_err then
      vim.notify(client_err, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return nil
    elseif response then
      handle_response(response, result.line1, result.line2)
      hooks.run_finished_hook()
    end

    return response
  end)

  coroutine.resume(co)
end

return fix
