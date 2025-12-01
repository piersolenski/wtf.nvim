local config = require("wtf.config")
local diagnose = require("wtf.commands.diagnose")
local fix = require("wtf.commands.fix")
local history = require("wtf.commands.history")
local hooks = require("wtf.hooks")
local pick_provider = require("wtf.commands.pick_provider")
local search = require("wtf.commands.search")
local copy = require("wtf.commands.copy")
local M = {}

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

function M.get_status()
  return hooks.get_status()
end

function M.grep_history()
  local pickers = require("wtf.pickers")
  return pickers.grep_history()
end

function M.history()
  return history()
end

function M.pick_provider()
  return pick_provider()
end

function M.search(opts)
  return search(opts)
end

function M.copy()
  return copy()
end
function M.setup(opts)
  config.setup(opts)
end
return M
