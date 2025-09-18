local config = require("wtf.config")

local M = {}

function M.is_available()
  local has_fzf_lua = pcall(require, "fzf-lua")
  return has_fzf_lua
end

function M.grep_history()
  if not M.is_available() then
    error("FZF-lua picker requires ibhagwan/fzf-lua")
  end

  local fzf_lua = require("fzf-lua")

  local opts = {
    cwd = config.options.chat_dir,
    winopts = {
      title = "WTF: Grep History",
    },
  }

  fzf_lua.live_grep(opts)
end

return M
