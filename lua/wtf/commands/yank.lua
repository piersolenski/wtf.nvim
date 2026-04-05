local get_diagnostics = require("wtf.util.diagnostics")
local get_line_range = require("wtf.util.get_line_range")

local function format_diagnostic(d)
  return string.format(
    "[%s] %s :L%d:C%d-L%d:C%d",
    d.severity:upper(),
    d.message,
    d.line_number,
    d.col,
    d.end_line_number,
    d.end_col
  )
end

local function yank_diagnostic(opts)
  local line1, line2 = get_line_range(opts)

  -- Return to normal mode only if in visual mode
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[vV]") or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
  end

  local diagnostics = get_diagnostics(line1, line2)

  if next(diagnostics) == nil then
    vim.notify("No diagnostics found!", vim.log.levels.WARN)
    return nil
  end

  local lines = {}
  for _, d in ipairs(diagnostics) do
    table.insert(lines, format_diagnostic(d))
  end
  local text = table.concat(lines, "\n")

  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify(#diagnostics == 1 and "Diagnostic yanked" or "Diagnostics yanked", vim.log.levels.INFO)

  return nil
end

return yank_diagnostic
