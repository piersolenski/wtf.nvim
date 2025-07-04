local client = require("wtf.ai.client")
local config = require("wtf.config")
local get_diagnostics = require("wtf.util.diagnostics")
local get_programming_language = require("wtf.util.get_programming_language")
local get_provider = require("wtf.util.get_provider")
local popup = require("wtf.ui.popup")
local save_chat = require("wtf.util.save_chat")

local function get_content_between_lines(start_line, end_line)
  local lines = {}
  for line_num = start_line, end_line do
    local line = string.format("%d: %s", line_num, vim.fn.getline(line_num))
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

local diagnose = function(line1, line2, instructions)
  -- Return the user to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)

  local diagnostics = get_diagnostics(line1, line2)
  local programming_language = get_programming_language()
  local should_send_code = config.options.context

  if next(diagnostics) == nil then
    local message = "No diagnostics found!"
    vim.notify(message, vim.log.levels.WARN)
    return message
  end

  local concatenatedDiagnostics = ""
  for i, diagnostic in ipairs(diagnostics) do
    concatenatedDiagnostics = concatenatedDiagnostics
      .. i
      .. ". Issue "
      .. i
      .. "\n\t- Location: Line "
      .. diagnostic.line_number
      .. "\n\t- Severity: "
      .. diagnostic.severity
      .. "\n\t- Message: "
      .. diagnostic.message
      .. "\n"
  end

  local code = get_content_between_lines(line1, line2)

  local payload = "The programming language is "
    .. programming_language
    .. ".\nThis is a list of the diagnostic messages: \n"
    .. concatenatedDiagnostics

  if should_send_code then
    payload = payload .. "This is the code for context: \n" .. "```\n" .. code .. "\n```"
  end

  if config.options.additional_instructions then
    payload = payload .. "\n" .. config.options.additional_instructions
  end

  if instructions then
    payload = payload .. "\n" .. instructions
  end

  local language = config.options.language
  if language and language ~= "english" then
    payload = payload .. "\nRespond only in " .. language
  end

  local provider = get_provider(config.options.provider)
  local model_id = config.options.providers[config.options.provider].model_id

  vim.notify("Diagnosing with " .. provider.formatted_name .. ": " .. model_id)

  local system = "You are an expert coder and helpful assistant who can help debug code diagnostics, "
    .. "such as warning and error messages."
    .. "When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier "
    .. "to enable syntax highlighting."
    .. "Never show line numbers on solutions, so they are easily copy and pastable."

  local co = coroutine.create(function()
    local response, err = client(provider, system, payload)

    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return nil
    end

    save_chat(response)

    local _, popup_err = popup.show(response)
    if popup_err then
      vim.notify(popup_err, vim.log.levels.ERROR)
    end
  end)

  coroutine.resume(co)
end

return diagnose
