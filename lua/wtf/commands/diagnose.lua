local client = require("wtf.ai.client")
local config = require("wtf.config")
local get_diagnostics = require("wtf.util.diagnostics")
local get_programming_language = require("wtf.util.get_programming_language")
local get_provider = require("wtf.util.get_provider")
local hooks = require("wtf.hooks")
local popup = require("wtf.ui.popup")
local save_chat = require("wtf.util.save_chat")

local SYSTEM_PROMPT = "You are an expert coder and helpful assistant who can help debug code diagnostics, "
  .. "such as warning and error messages. "
  .. "When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier "
  .. "to enable syntax highlighting. "
  .. "Never show line numbers on solutions, so they are easily copy and pastable."

--- Get content between specified lines with line numbers
--- @param start_line number
--- @param end_line number
--- @return string
local function get_content_between_lines(start_line, end_line)
  local lines = {}
  for line_num = start_line, end_line do
    local line = string.format("%d: %s", line_num, vim.fn.getline(line_num))
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

--- Format diagnostics into a readable string
--- @param diagnostics table
--- @return string
local function format_diagnostics(diagnostics)
  local formatted_parts = {}

  for i, diagnostic in ipairs(diagnostics) do
    local diagnostic_text = string.format(
      "%d. Issue %d\n\t- Location: Line %d\n\t- Severity: %s\n\t- Message: %s",
      i,
      i,
      diagnostic.line_number,
      diagnostic.severity,
      diagnostic.message
    )
    table.insert(formatted_parts, diagnostic_text)
  end

  return table.concat(formatted_parts, "\n")
end

--- Build the payload for the AI request
--- @param programming_language string
--- @param diagnostics_text string
--- @param code string|nil
--- @param instructions string|nil
--- @return string
local function build_payload(programming_language, diagnostics_text, code, instructions)
  local payload_parts = {
    "The programming language is " .. programming_language .. ".",
    "This is a list of the diagnostic messages:",
    diagnostics_text,
  }

  table.insert(payload_parts, "This is the code for context: ```\n" .. code .. "\n```")

  if config.options.additional_instructions then
    table.insert(payload_parts, config.options.additional_instructions)
  end

  if instructions then
    table.insert(payload_parts, instructions)
  end

  local language = config.options.language
  if language and language ~= "english" then
    table.insert(payload_parts, "Respond only in " .. language)
  end

  return table.concat(payload_parts, "\n")
end

--- Handle the AI response
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

--- Determine line range based on options or current mode
--- @param opts table|nil Options containing line1, line2, and instructions
--- @return number line1, number line2
local function get_line_range(opts)
  if opts and opts.line1 and opts.line2 then
    return opts.line1, opts.line2
  end

  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match("^[vV]")

  if is_visual then
    -- Get visual range before escaping visual mode
    local start_line = vim.fn.getpos("v")[2]
    local end_line = vim.fn.getcurpos()[2]
    -- Ensure start_line is always less than or equal to end_line
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    return start_line, end_line
  else
    local current_line = vim.fn.line(".")
    return current_line, current_line
  end
end

--- Main diagnostic function
--- @param opts table|nil Options containing line1, line2, and instructions
--- @return string|nil
local function diagnose(opts)
  hooks.run_started_hook()

  local line1, line2 = get_line_range(opts)

  -- Return to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)

  local instructions = opts and opts.instructions

  local diagnostics = get_diagnostics(line1, line2)
  if not diagnostics or next(diagnostics) == nil then
    local message = "No diagnostics found!"
    vim.notify(message, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return message
  end

  local programming_language = get_programming_language()
  local diagnostics_text = format_diagnostics(diagnostics)
  local code = get_content_between_lines(line1, line2)
  local payload = build_payload(programming_language, diagnostics_text, code, instructions)

  local provider = get_provider(config.options.provider)
  local model_id = config.options.providers[config.options.provider].model_id

  vim.notify("Diagnosing with " .. provider.formatted_name .. ": " .. model_id)

  -- Use coroutine since client function is async
  local co = coroutine.create(function()
    local response, err = client(provider, SYSTEM_PROMPT, payload)

    if err then
      vim.notify(err, vim.log.levels.ERROR)
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
