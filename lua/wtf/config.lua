local search_engines = require("wtf.search_engines")

local M = {}

M.options = {}

function M.setup(opts)
  local default_opts = {
    openai_api_key = nil,
    openai_api_key_cmd = nil,
    openai_model_id = "gpt-3.5-turbo",
    language = "english",
    search_engine = "google",
    context = true,
    additional_instructions = nil,
    popup_type = "popup",
    hooks = {
      request_started = nil,
      request_finished = nil,
    },
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  }

  -- Merge default_opts with opts
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  vim.validate({
    winhighlight = { opts.winhighlight, "string" },
    openai_api_key = { opts.openai_api_key, { "string", "nil" } },
    openai_api_key_cmd = { opts.openai_api_key_cmd, { "string", "nil" } },
    openai_model_id = { opts.openai_model_id, "string" },
    language = { opts.language, "string" },
    search_engine = {
      opts.search_engine,
      function(search_engine)
        local selected_engine = search_engines.sources[search_engine]

        if not selected_engine then
          return false
        else
          return true
        end
      end,
      "supported search engine",
    },
    context = { opts.context, "boolean" },
    additional_instructions = { opts.additional_instructions, { "string", "nil" } },
    popup_type = {
      opts.popup_type,
      function(popup_type)
        local popup_types = { "horizontal", "vertical", "popup" }

        for _, valid_type in ipairs(popup_types) do
          if popup_type == valid_type then
            return true
          end
        end
        return false
      end,
      "supported popup type",
    },
    request_started = {
      opts.hooks.request_started,
      { "function", "nil" },
    },
    request_finished = {
      opts.hooks.request_finished,
      { "function", "nil" },
    },
  })

  M.options = vim.tbl_extend("force", M.options, opts)
end

return M
