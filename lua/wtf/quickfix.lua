local config = require("wtf.config")
local create_summary = require("wtf.utils.create_summary")

local function populate_quickfix_with_history()
  local directory = config.options.chat_dir
  local files = {}
  local handle = vim.loop.fs_scandir(directory)
  local summary_length = 200

  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == "file" then
        local filepath = directory .. "/" .. name
        local fd = vim.loop.fs_open(filepath, "r", 438)
        if fd then
          local stat = vim.loop.fs_fstat(fd)
          if stat then
            local data = vim.loop.fs_read(fd, stat.size, 0)
            if data then
              local summary = create_summary(data, summary_length)
              table.insert(files, {
                filename = filepath,
                lnum = 1,
                text = summary,
              })
            end
          end
          vim.loop.fs_close(fd)
        end
      end
    end
  end

  -- Add files to quickfix list
  vim.fn.setqflist({}, " ", {
    title = "WTF History",
    items = files,
  })

  -- Open quickfix window
  vim.cmd("copen")
end

return populate_quickfix_with_history
