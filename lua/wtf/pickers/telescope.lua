local config = require("wtf.config")

local M = {}

function M.is_available()
  local has_telescope = pcall(require, "telescope")
  return has_telescope
end

function M.grep_history()
  if not M.is_available() then
    error("Telescope picker requires nvim-telescope/telescope.nvim")
  end

  local builtin = require("telescope.builtin")

  local opts = {
    cwd = config.options.chat_dir,
    prompt_title = "WTF: Grep History",
  }

  builtin.live_grep(opts)
end

return M
