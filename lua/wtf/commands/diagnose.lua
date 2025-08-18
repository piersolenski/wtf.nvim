local client = require("wtf.ai.client")
local config = require("wtf.config")
local hooks = require("wtf.hooks")
local notify = require("wtf.util.notify")
local popup = require("wtf.ui.popup")
local process_diagnostics = require("wtf.util.process_diagnostics")
local save_chat = require("wtf.util.save_chat")

--- @param response string
--- @return boolean success
local function handle_response(response)
  save_chat(response)

  local success, popup_err = popup.show(response)
  if popup_err then
    vim.notify(popup_err, vim.log.levels.ERROR)
    return false
  end

  return success ~= nil and success or false
end

local function diagnose(opts)
  hooks.run_started_hook()

  local language = config.options.language

  local SYSTEM_PROMPT = "You are an expert coder and helpful assistant who can help debug code diagnostics, "
    .. "such as warning and error messages. "
    .. "When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier "
    .. "to enable syntax highlighting. "
    .. "Never show line numbers on solutions, so they are easily copy and pastable."
    .. "Always explain in"
    .. language

  local result = process_diagnostics(opts)
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return result.err
  end

  notify.ai_task_started("Diagnosing")

  -- Use coroutine since client function is async
  local co = coroutine.create(function()
    local response, client_err = client(SYSTEM_PROMPT, result.payload, 0.7)

    if client_err then
      vim.notify(client_err, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return nil
    elseif response then
      handle_response(response)
      hooks.run_finished_hook()
    end

    return response
  end)

  coroutine.resume(co)
end

return diagnose
