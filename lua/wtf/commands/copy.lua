local config = require("wtf.config")
local process_diagnostics = require("wtf.util.process_diagnostics")

--- @param opts table|nil
--- @return string|nil error
local function copy_diagnostic(opts)
  local result = process_diagnostics(opts)
  
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    return result.err
  end
  
  -- Copy the diagnostic payload to clipboard
  vim.fn.setreg('+', result.payload)
  
  -- Also copy to unnamed register as fallback
  vim.fn.setreg('"', result.payload)
  
  vim.notify("Diagnostic copied to clipboard", vim.log.levels.INFO)
  
  return nil
end

return copy_diagnostic
