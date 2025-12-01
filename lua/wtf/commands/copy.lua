--- @return string|nil error
local function copy_diagnostic()
  -- Get diagnostics at current cursor position
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

  if #diagnostics == 0 then
    vim.notify("No diagnostic at cursor line", vim.log.levels.WARN)
    return "No diagnostic found"
  end

  --- Helper function to perform the actual copy
  local function copy_message(message)
    vim.fn.setreg('+', message)
    vim.fn.setreg('"', message)
    vim.notify("Diagnostic copied: " .. message, vim.log.levels.INFO)
  end

  if #diagnostics > 1 then
    -- More than one diagnostic, show a selection menu
    local opts = {
      prompt = "Choose a diagnostic to copy:",
      format_item = function(item)
        -- NOTE: If you have a `remove_file_paths` function defined,
        -- you can call it here, like in your example:
        -- return remove_file_paths(item.message)
        return item.message
      end,
    }

    vim.ui.select(diagnostics, opts, function(chosen_diagnostic)
      if chosen_diagnostic then
        -- User selected one, copy its message
        copy_message(chosen_diagnostic.message)
      end
    end)
  else
    -- Only one diagnostic, copy it directly
    local diagnostic = diagnostics[1]
    copy_message(diagnostic.message)
  end

  return nil
end

return copy_diagnostic
