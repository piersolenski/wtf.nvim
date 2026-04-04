--- Determine line range based on options or current mode
--- @param opts table|nil Options containing line1, line2
--- @return number line1, number line2
local function get_line_range(opts)
  if opts and opts.line1 and opts.line2 then
    return opts.line1, opts.line2
  end

  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match("^[vV]") or mode == "\22"

  if is_visual then
    -- Get visual range before escaping visual mode
    local start_line = vim.fn.getpos("v")[2]
    local end_line = vim.fn.getcurpos()[2]
    -- Ensure start_line is always less than or equal to end_line
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    return start_line, end_line
  else
    local current_line = vim.fn.line(".")
    return current_line, current_line
  end
end

return get_line_range
