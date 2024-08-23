local config = require("wtf.config")

local function create_safe_filename(input_string, filename_length)
  local filename

  -- First strip potentially unsafe characters; keeping alphanumerics, hyphens, underscores, and spaces
  -- Add any other characters you want to keep where newline, :, /, \, *, ?, ", <, >, | are typically problematic
  local safe_string = input_string:gsub('[<>:"/\\|?*%c]', "")

  -- Truncate string
  if #safe_string > filename_length then
    filename = safe_string:sub(1, filename_length)
  end

  return filename
end

local function save_chat(message)
  local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
  local summary = create_safe_filename(message, 50)
  local file = config.options.chat_dir .. "/" .. timestamp .. summary .. ".md"

  -- Ensure the chat directory exists
  vim.fn.mkdir(config.options.chat_dir, "p")

  -- Write the file
  vim.fn.writefile(vim.split(message, "\n"), file)
end

return save_chat
