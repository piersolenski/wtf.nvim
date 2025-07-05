local function get_programming_language()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

  if filetype == "cpp" then
    return "C++"
  else
    return filetype
  end
end

return get_programming_language
