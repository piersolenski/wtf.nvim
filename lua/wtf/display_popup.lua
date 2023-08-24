local Split = require("nui.split")
local Popup = require("nui.popup")

local function get_popup_type()
  return vim.g.wtf_popup_type
end

local function split_string_by_line(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

local function display_popup(responseTable)
  -- Clear last command
  print(" ")

  if responseTable == nil then
    return nil
  end
  local message = responseTable.choices[1].message.content
  message = split_string_by_line(message)

  local event = require("nui.utils.autocmd").event

  local popup
  local popup_opts = {
    relative = "editor",
    buf_options = {
      modifiable = false,
      readonly = true,
      filetype = "markdown",
    },
    win_options = {
      wrap = true,
      linebreak = true,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  }

  local popup_type = get_popup_type()

  if popup_type == "vertical" then
    popup = Split(vim.tbl_deep_extend("keep", popup_opts, {
      position = "right",
      size = "50%",
    }))
  elseif popup_type == "horizontal" then
    popup = Split(vim.tbl_deep_extend("keep", popup_opts, {
      position = "bottom",
      size = "38%",
    }))
  elseif popup_type == "popup" then
    popup = Popup(vim.tbl_deep_extend("keep", popup_opts, {
      position = "50%",
      size = {
        width = "62%",
        height = "62%",
      },
      padding = { 1, 1, 1, 1 },
      enter = true,
      focusable = true,
      zindex = 50,
      border = {
        style = "rounded",
      },
    }))
  else
    return print("Invalid popup_type.")
  end

  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, message)

  popup:mount()

  -- unmount component when cursor leaves buffer
  popup:on(event.BufLeave, function()
    popup:unmount()
  end)
end

return display_popup
