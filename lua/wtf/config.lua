local providers = require("wtf.ai.providers")
local search_engines = require("wtf.sources.search_engines")

local function get_provider_names(p)
  return vim.tbl_keys(p)
end

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

-- Validation helpers
local function validate_provider(provider)
  return vim.tbl_contains(get_provider_names(providers), provider)
end

local function validate_search_engine(search_engine)
  return search_engines.sources[search_engine] ~= nil
end

local function validate_popup_type(popup_type)
  return vim.tbl_contains({ "horizontal", "vertical", "popup" }, popup_type)
end

local function create_deprecation_validator(old_key, new_key)
  return function(val)
    if val ~= nil then
      vim.notify(
        string.format("WTF %s should now be set via %s", old_key, new_key),
        vim.log.levels.ERROR
      )
    end
    return true
  end
end

local function get_validation_spec(opts)
  return {
    openai_api_key = {
      opts.openai_api_key,
      create_deprecation_validator("openai_api_key", "providers.openai.api_key"),
    },
    openai_model_id = {
      opts.openai_model_id,
      create_deprecation_validator("openai_model_id", "providers.openai.model_id"),
    },
    context = {
      opts.context,
      function(val)
        if val ~= nil then
          vim.notify(
            "context is no longer supported, please remove it from your config",
            vim.log.levels.ERROR
          )
        end
        return true
      end,
    },
    winhighlight = { opts.winhighlight, "string" },
    provider = { opts.provider, validate_provider, "supported provider" },
    providers = { opts.providers, { "table", "nil" } },
    language = { opts.language, "string" },
    search_engine = { opts.search_engine, validate_search_engine, "supported search engine" },
    additional_instructions = { opts.additional_instructions, { "string", "nil" } },
    popup_type = { opts.popup_type, validate_popup_type, "supported popup type" },
    request_started = { opts.hooks.request_started, { "function", "nil" } },
    request_finished = { opts.hooks.request_finished, { "function", "nil" } },
  }
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

  vim.validate(get_validation_spec(merged_opts))

  M.options = vim.tbl_extend("force", M.options, merged_opts)
end

return M
