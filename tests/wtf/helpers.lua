local M = {}

local buffer_number = 0
local namespace = nil

M.line_with_error = 3

M.set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

M.create_errors = function(diagnostics)
  local diag_table = {}
  namespace = vim.api.nvim_create_namespace("wtf")

  for _, d in ipairs(diagnostics) do
    table.insert(diag_table, {
      bufnr = M.buffer_number,
      lnum = d.line - 1,
      end_lnum = d.line - 1,
      col = 0,
      end_col = 5,
      severity = vim.diagnostic.severity.ERROR,
      message = d.message,
    })
    vim.api.nvim_win_set_cursor(0, { d.line, 0 })
  end

  vim.diagnostic.set(namespace, buffer_number, diag_table)

  return diag_table
end

return M
