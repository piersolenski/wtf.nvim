local providers = require("wtf.ai.providers")
local search_engines = require("wtf.sources.search_engines")

local M = {}

local function get_provider_names(p)
  return vim.tbl_keys(p)
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

function M.validate_opts(opts)
  -- TODO: Remove in future version
  vim.validate(
    "openai_api_key",
    opts.openai_api_key,
    create_deprecation_validator("openai_api_key", "providers.openai.api_key")
  )
  -- TODO: Remove in future version
  vim.validate(
    "openai_model_id",
    opts.openai_model_id,
    create_deprecation_validator("openai_model_id", "providers.openai.model_id")
  )
  vim.validate("context", opts.context, function(val)
    if val ~= nil then
      vim.notify(
        "context is no longer supported, please remove it from your config",
        vim.log.levels.ERROR
      )
    end
    return true
  end)
  vim.validate("winhighlight", opts.winhighlight, "string")
  vim.validate("provider", opts.provider, validate_provider, "supported provider")
  vim.validate("providers", opts.providers, { "table", "nil" })
  vim.validate("language", opts.language, "string")
  vim.validate(
    "search_engine",
    opts.search_engine,
    validate_search_engine,
    "supported search engine"
  )
  vim.validate("additional_instructions", opts.additional_instructions, { "string", "nil" })
  vim.validate("popup_type", opts.popup_type, validate_popup_type, "supported popup type")
  vim.validate("request_started", opts.hooks.request_started, { "function", "nil" })
  vim.validate("request_finished", opts.hooks.request_finished, { "function", "nil" })
end

return M
