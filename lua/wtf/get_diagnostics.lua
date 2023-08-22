local function get_diagnostics()
  local line = vim.fn.line(".") - 1
  local bufnr = vim.api.nvim_win_get_buf(0)
  local diagnostics = vim.diagnostic.get(bufnr, {
    lnum = line,
    severity = { min = vim.diagnostic.severity.HINT },
  })

  if #diagnostics == 0 then
    return nil
  end

  local obj = {}

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(obj, {
      message = diagnostic.message,
      severity = vim.diagnostic.severity[diagnostic.severity],
    })
  end

  return obj
end

return get_diagnostics
