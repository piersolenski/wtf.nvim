local function copy_diagnostic(opts)
  -- If you wanted to copy the full formatted output:
  local result = process_diagnostics(opts)
  
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    return result.err
  end
  
  vim.fn.setreg('+', result.payload)
  vim.notify("Diagnostics copied to clipboard", vim.log.levels.INFO)
  
  return nil
end

return copy_diagnostic
