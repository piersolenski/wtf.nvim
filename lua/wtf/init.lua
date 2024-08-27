local ai = require("wtf.ai")
local search = require("wtf.search")
local config = require("wtf.config")
local quickfix = require("wtf.quickfix")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.ai(opts)
  if opts and opts.line1 and opts.line2 then
    return ai.diagnose(opts.line1, opts.line2, opts.instructions)
  else
    local mode = vim.api.nvim_get_mode().mode
    local is_visual = mode:match("^[vV]")

    if is_visual then
      local start_line, end_line = vim.fn.getpos("v")[2], vim.fn.getcurpos()[2]
      return ai.diagnose(start_line, end_line, opts and opts.instructions)
    else
      local current_line = vim.fn.line(".")
      return ai.diagnose(current_line, current_line, opts and opts.instructions)
    end
  end
end

function M.search(opts)
  return search(opts)
end

function M.get_status()
  return ai.get_status()
end

function M.grep_history()
  local telescope = require("telescope")
  telescope.load_extension("wtf")
  return telescope.extensions.wtf.grep_history()
end

function M.history()
  return quickfix()
end

return M
