local get_diagnostics = require("wtf.util.diagnostics")
local remove_file_paths = require("wtf.util.remove_file_paths")

local function yank_message(message)
  vim.fn.setreg("+", message)
  vim.fn.setreg('"', message)
  vim.notify("Diagnostic yanked: " .. message, vim.log.levels.INFO)
end

local function yank_diagnostic()
  local line = vim.fn.line(".")
  local diagnostics = get_diagnostics(line)

  if next(diagnostics) == nil then
    vim.notify("No diagnostics found!", vim.log.levels.WARN)
    return nil
  end

  if #diagnostics > 1 then
    local opts = {
      prompt = "Choose a diagnostic to yank:",
      format_item = function(item)
        return remove_file_paths(item.message)
      end,
    }
    vim.ui.select(diagnostics, opts, function(chosen_diagnostic)
      if chosen_diagnostic then
        yank_message(chosen_diagnostic.message)
      end
    end)
  else
    yank_message(diagnostics[1].message)
  end

  return nil
end

return yank_diagnostic
