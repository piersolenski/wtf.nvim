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

local function validate_picker(picker)
  return vim.tbl_contains({ "telescope", "snacks", "fzf-lua" }, picker)
end

function M.validate_opts(opts)
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
  vim.validate("picker", opts.picker, validate_picker, "supported picker")
  vim.validate("popup_type", opts.popup_type, validate_popup_type, "supported popup type")
  vim.validate("request_started", opts.hooks.request_started, { "function", "nil" })
  vim.validate("request_finished", opts.hooks.request_finished, { "function", "nil" })
end

return M
