local ai = require("wtf.ai")
local search = require("wtf.search")
local gpt = require("wtf.gpt")

local M = {}

local default_opts = {
  openai_api_key = nil,
  openai_model_id = "gpt-3.5-turbo",
  language = "english",
  search_engine = "google",
  additional_instructions = nil,
  popup_type = "popup",
}

function M.setup(opts)
  -- Merge default_opts with opts
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  vim.g.wtf_openai_api_key = opts.openai_api_key
  vim.g.wtf_openai_model_id = opts.openai_model_id
  vim.g.wtf_language = opts.language
  vim.g.wtf_search_engine = opts.search_engine
  vim.g.wtf_default_additional_instructions = opts.additional_instructions
  vim.g.wtf_popup_type = opts.popup_type
  vim.g["wtf_hooks"] = {
    request_started = nil,
    request_finished = nil,
  }
end

function M.ai(additional_instructions)
  return ai(additional_instructions)
end

function M.search(opts)
  return search(opts)
end

function M.get_status()
  return gpt.get_status()
end

return M
