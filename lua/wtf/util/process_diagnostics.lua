local config = require("wtf.config")
local get_diagnostics = require("wtf.util.diagnostics")
local get_line_range = require("wtf.util.get_line_range")
local get_programming_language = require("wtf.util.get_programming_language")

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
    local location
    if diagnostic.end_line_number and diagnostic.end_line_number ~= diagnostic.line_number then
      location = string.format(
        "Lines %d-%d, Columns %d-%d",
        diagnostic.line_number,
        diagnostic.end_line_number,
        diagnostic.col,
        diagnostic.end_col
      )
    else
      location = string.format(
        "Line %d, Columns %d-%d",
        diagnostic.line_number,
        diagnostic.col,
        diagnostic.end_col
      )
    end

    local diagnostic_text = string.format(
      "%d. Issue %d\n\t- Location: %s\n\t- Severity: %s\n\t- Message: %s",
      i,
      i,
      location,
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

  return table.concat(payload_parts, "\n")
end

--- Process diagnostics for a given range
--- @param opts table|nil Options containing line1, line2, and instructions
--- @return {err: string}|{line1: number, line2: number, payload: any}
local function process_diagnostics(opts)
  local line1, line2 = get_line_range(opts)

  -- Return to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)

  local instructions = opts and opts.instructions

  local diagnostics = get_diagnostics(line1, line2)
  if not diagnostics or next(diagnostics) == nil then
    return { err = "No diagnostics found!" }
  end

  local programming_language = get_programming_language()
  local diagnostics_text = format_diagnostics(diagnostics)
  local code = get_content_between_lines(line1, line2)
  local payload = build_payload(programming_language, diagnostics_text, code, instructions)

  return { line1 = line1, line2 = line2, payload = payload }
end

return process_diagnostics
