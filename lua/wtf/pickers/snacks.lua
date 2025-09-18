local config = require("wtf.config")

local M = {}

function M.is_available()
  local has_snacks = pcall(require, "snacks")
  if not has_snacks then
    return false
  end

  local snacks = require("snacks")
  return snacks.picker ~= nil
end

function M.grep_history()
  if not M.is_available() then
    error("Snacks picker requires folke/snacks.nvim with picker enabled")
  end

  local snacks = require("snacks")

  local opts = {
    cwd = config.options.chat_dir,
    title = "WTF: Grep History",
  }

  snacks.picker.grep(opts)
end

return M
