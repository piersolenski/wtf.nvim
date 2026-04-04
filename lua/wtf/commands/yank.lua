local get_diagnostics = require("wtf.util.diagnostics")
local get_line_range = require("wtf.util.get_line_range")
local remove_file_paths = require("wtf.util.remove_file_paths")

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

local function yank_text(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Diagnostic yanked", vim.log.levels.INFO)
end

local function yank_diagnostic(opts)
  local line1, line2 = get_line_range(opts)

  -- Return to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)

  local is_range = line1 ~= line2
  local diagnostics = get_diagnostics(line1, line2)

  if next(diagnostics) == nil then
    vim.notify("No diagnostics found!", vim.log.levels.WARN)
    return nil
  end

  if is_range or #diagnostics == 1 then
    local lines = {}
    for _, d in ipairs(diagnostics) do
      table.insert(lines, format_diagnostic(d))
    end
    yank_text(table.concat(lines, "\n"))
  else
    vim.ui.select(diagnostics, {
      prompt = "Choose a diagnostic to yank:",
      format_item = function(item)
        return remove_file_paths(item.message)
      end,
    }, function(chosen)
      if chosen then
        yank_text(format_diagnostic(chosen))
      end
    end)
  end

  return nil
end

return yank_diagnostic
