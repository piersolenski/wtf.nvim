local providers = require("wtf.ai.providers")
local search_engines = require("wtf.sources.search_engines")

local M = {}

M.options = {}

function M.setup(opts)
  local default_opts = {
    additional_instructions = nil,
    chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/wtf/chats",
    language = "english",
    popup_type = "popup",
    provider = "openai",
    -- TODO: Don't set model IDs here
    providers = {
      anthropic = {
        model_id = "claude-3-5-sonnet-20241022",
      },
      copilot = {
        model_id = "gpt-4o",
      },
      deepseek = {
        model_id = "deepseek-chat",
      },
      gemini = {
        model_id = "gemini-2.5-flash",
      },
      grok = {
        model_id = "grok-3-latest",
      },
      ollama = {
        model_id = "deepseek-r1",
      },
      openai = {
        model_id = "gpt-4o",
      },
    },
    search_engine = "google",
    hooks = {
      request_started = nil,
      request_finished = nil,
    },
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  }

  -- Merge default_opts with opts
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  vim.validate({
    -- TODO: Remove openai_api_key in a future version
    openai_api_key = {
      opts.openai_api_key,
      function(val)
        if val ~= nil then
          vim.notify(
            "WTF openai_api_key should now be set via providers.openai.api_key",
            vim.log.levels.ERROR
          )
        end
        return true
      end,
    },
    -- TODO: Remove openai_model_id in a future version
    openai_model_id = {
      opts.openai_model_id,
      function(val)
        if val ~= nil then
          vim.notify(
            "WTF openai_model_id should now be set via providers.openai.model_id",
            vim.log.levels.ERROR
          )
        end
        return true
      end,
    },
    winhighlight = { opts.winhighlight, "string" },
    -- TODO: Add more stringent validation
    provider = {
      opts.provider,
      function(provider)
        for _, supported_provider in ipairs(providers.get_names()) do
          if provider == supported_provider then
            return true
          end
        end
        return false
      end,
      "supported provider",
    },
    providers = { opts.providers, { "table", "nil" } },
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
    -- TODO: Remove context in a future version
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
