local config = require("wtf.config")
local telescope = require("telescope")
local builtin = require("telescope.builtin")

local history = function()
  local opts = {
    cwd = config.options.chat_dir,
    prompt_title = "WTF: Grep History",
  }
  builtin.live_grep(opts)
end

return telescope.register_extension({ exports = { history = history } })
