local to_title_case = require("wtf.utils.to_title_case")

local function get_diagnostics(range_start, range_end)
  if range_end == nil then
    range_end = range_start
  end

  -- local bufnr = vim.api.nvim_win_get_buf(0)
  local bufnr = vim.api.nvim_get_current_buf()

  local diagnostics = {}

  for line_num = range_start, range_end do
    local line_diagnostics = vim.diagnostic.get(bufnr, {
      lnum = line_num - 1,
      severity = { min = vim.diagnostic.severity.HINT },
    })

    if next(line_diagnostics) ~= nil then
      for _, diagnostic in ipairs(line_diagnostics) do
        table.insert(diagnostics, {
          line_number = line_num,
          message = diagnostic.message,
          severity = to_title_case(vim.diagnostic.severity[diagnostic.severity]),
        })
      end
    end
  end

  return diagnostics
end

return get_diagnostics
