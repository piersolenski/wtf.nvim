local config = require("wtf.config")
local telescope = require("telescope")
local builtin = require("telescope.builtin")

local grep_history = function()
  local opts = {
    cwd = config.options.chat_dir,
    prompt_title = "WTF: Grep History",
  }
  builtin.live_grep(opts)
end

return telescope.register_extension({ exports = { grep_history = grep_history } })
