local config = require("wtf.config")

local status_index = 0
local progress_bar_dots = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local callback_counter = 0

local M = {}

M.run_started_hook = function()
  local request_started = config.options.hooks and config.options.hooks.request_started
  if request_started ~= nil then
    request_started()
  end

  callback_counter = callback_counter + 1
end

M.run_finished_hook = function()
  callback_counter = callback_counter - 1
  if callback_counter <= 0 then
    local request_finished = config.options.hooks and config.options.hooks.request_finished
    if request_finished ~= nil then
      request_finished()
    end
  end
end

M.get_status = function()
  if callback_counter > 0 then
    status_index = status_index + 1
    if status_index > #progress_bar_dots then
      status_index = 1
    end
    return progress_bar_dots[status_index]
  else
    return ""
  end
end

return M
