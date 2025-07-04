local config = require("wtf.config")
local get_provider = require("wtf.util.get_provider")

local M = {}

M.ai_task_started = function(type)
  local provider = get_provider(config.options.provider)
  local model_id = config.options.providers[config.options.provider].model_id
  vim.notify(type .. " with " .. provider.formatted_name .. ": " .. model_id)
end

return M
