local providers = require("wtf.ai.providers")
local validation = require("wtf.validation")

local function create_provider_defaults()
  local defaults = {}
  for name, provider in pairs(providers) do
    defaults[name] = {
      model_id = provider.model_id,
      api_key = provider.api_key,
    }
  end
  return defaults
end

local M = {}

M.options = {}

function M.setup(opts)
  opts = opts or {}

  local default_opts = {
    additional_instructions = nil,
    chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/wtf/chats",
    language = "english",
    popup_type = "horizontal",
    provider = "openai",
    search_engine = "google",
    providers = create_provider_defaults(),
    hooks = {
      request_started = nil,
      request_finished = nil,
    },
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  }

  -- Merge user providers with defaults
  local merged_opts = vim.tbl_deep_extend("force", default_opts, opts)
  if opts.providers then
    merged_opts.providers = vim.tbl_deep_extend("force", default_opts.providers, opts.providers)
  end

  vim.validate(validation.get_validation_spec(merged_opts))

  M.options = vim.tbl_extend("force", M.options, merged_opts)
end

return M
