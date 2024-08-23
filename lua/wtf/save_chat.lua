local config = require("wtf.config")

local function save_chat(message)
  local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
  local file = config.options.chat_dir .. "/" .. timestamp .. ".md"

  -- Ensure the chat directory exists
  vim.fn.mkdir(config.options.chat_dir, "p")

  -- Write the file
  vim.fn.writefile(vim.split(message, "\n"), file)
end

return save_chat
