---@module 'luassert'

local M = {}

local namespace = nil

M.line_with_error = 3

M.create_lines = function(lines)
  if vim.api.nvim_buf_set_lines then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
end

M.create_errors = function(diagnostics)
  local diag_table = {}
  namespace = vim.api.nvim_create_namespace("wtf")

  local current_bufnr = vim.api.nvim_get_current_buf()
  for _, d in ipairs(diagnostics) do
    table.insert(diag_table, {
      bufnr = current_bufnr,
      lnum = d.line - 1,
      end_lnum = d.line - 1,
      col = 0,
      end_col = 5,
      severity = vim.diagnostic.severity.ERROR,
      message = d.message,
    })
    vim.api.nvim_win_set_cursor(0, { d.line, 0 })
  end

  vim.diagnostic.set(namespace, current_bufnr, diag_table)

  return diag_table
end

M.disable_notifications = function()
  -- Mock vim.notify to ignore notifications in test output
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function() end
end

return M
