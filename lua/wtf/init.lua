local config = require("wtf.config")
local diagnose = require("wtf.actions.diagnose")
local hooks = require("wtf.hooks")
local history = require("wtf.actions.history")
local search = require("wtf.actions.search")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

-- TODO: Remove this in a later version
function M.ai(opts)
  vim.notify("M.ai() is deprecated and will be removed soon. Use M.diagnose() instead.", vim.log.levels.WARN)
  return M.diagnose(opts)
end

function M.diagnose(opts)
  if opts and opts.line1 and opts.line2 then
    return diagnose(opts.line1, opts.line2, opts.instructions)
  else
    local mode = vim.api.nvim_get_mode().mode
    local is_visual = mode:match("^[vV]")

    if is_visual then
      local start_line, end_line = vim.fn.getpos("v")[2], vim.fn.getcurpos()[2]
      return diagnose(start_line, end_line, opts and opts.instructions)
    else
      local current_line = vim.fn.line(".")
      return diagnose(current_line, current_line, opts and opts.instructions)
    end
  end
end

function M.search(opts)
  return search(opts)
end

function M.get_status()
  return hooks.get_status()
end

function M.grep_history()
  local has_telescope, telescope = pcall(require, "telescope")

  if not has_telescope then
    error("This feature requires nvim-telescope/telescope.nvim")
  end
  telescope.load_extension("wtf")
  return telescope.extensions.wtf.grep_history()
end

function M.history()
  return history()
end

return M
