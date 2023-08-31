local get_diagnostics = require("wtf.get_diagnostics")
local get_programming_language = require("wtf.utils.get_programming_language")
local gpt = require("wtf.gpt")
local display_popup = require("wtf.display_popup")
local config = require("wtf.config")

local M = {}

local function get_content_between_lines(start_line, end_line)
  local lines = {}
  for line_num = start_line, end_line do
    local line = string.format("%d: %s", line_num, vim.fn.getline(line_num))
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

M.diagnose = function(line1, line2, instructions)
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

  vim.notify("Generating explanation...", vim.log.levels.INFO)

  local messages = {
    {
      role = "system",
      content = [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages.
      When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting.]],
    },
    {
      role = "user",
      content = payload,
    },
  }

  return gpt.request(messages, display_popup)
end

M.get_status = gpt.get_status

return M
