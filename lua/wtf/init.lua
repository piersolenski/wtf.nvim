local config = require("wtf.config")
local diagnose = require("wtf.commands.diagnose")
local fix = require("wtf.commands.fix")
local history = require("wtf.commands.history")
local hooks = require("wtf.hooks")
local search = require("wtf.commands.search")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

-- TODO: Remove this in a later version
function M.ai(opts)
  vim.notify(
    "M.ai() is deprecated and will be removed soon. Use M.diagnose() instead.",
    vim.log.levels.WARN
  )
  return M.diagnose(opts)
end

function M.diagnose(opts)
  return diagnose(opts)
end

function M.fix(opts)
  return fix(opts)
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
