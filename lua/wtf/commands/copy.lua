--- Copy the diagnostic message at cursor to clipboard
--- @return string|nil error
local function copy_diagnostic()
  -- Get diagnostics at current cursor position
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  
  if #diagnostics == 0 then
    vim.notify("No diagnostic at cursor line", vim.log.levels.WARN)
    return "No diagnostic found"
  end
  
  -- Get the first diagnostic message
  local message = diagnostics[1].message
  
  -- Copy to clipboard
  vim.fn.setreg('+', message)
  vim.fn.setreg('"', message)
  
  vim.notify("Diagnostic copied: " .. message, vim.log.levels.INFO)
  
  return nil
end

return copy_diagnostic
