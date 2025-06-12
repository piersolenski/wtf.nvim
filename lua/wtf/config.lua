local search_engines = require("wtf.search_engines")

local M = {}

M.options = {}

function M.setup(opts)
  local default_opts = {
    additional_instructions = nil,
    chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/wtf/chats",
    context = true,
    language = "english",
    provider = "gpt",
    providers = {
      gpt = {
        apiKey = nil,
        modelId = "gpt-3.5-turbo",
        baseUrl = "https://api.openai.com",
      },
      gemini = {
        apiKey = nil,
        modelId = "gemini-1.5-flash",
        baseUrl = "https://generativeai.googleapis.com",
      },
    },
    popup_type = "popup",
    search_engine = "google",
    hooks = {
      request_started = nil,
      request_finished = nil,
    },
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  }

  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  local function is_valid_provider(pr)
    return type(pr) == "table"
      and (pr.apiKey == nil or type(pr.apiKey) == "string")
      and (pr.modelId == nil or type(pr.modelId) == "string")
      and (pr.baseUrl == nil or type(pr.baseUrl) == "string")
  end

  vim.validate({
    provider = { opts.provider, "string" },
    providers = {
      opts.providers,
      function(p)
        for _, config in pairs(p) do
          if not is_valid_provider(config) then
            return false
          end
        end
        return true
      end,
      "all providers must have valid structure",
    },
    winhighlight = { opts.winhighlight, "string" },
    language = { opts.language, "string" },
    search_engine = {
      opts.search_engine,
      function(search_engine)
        return search_engines.sources[search_engine] ~= nil
      end,
      "supported search engine",
    },
    context = { opts.context, "boolean" },
    additional_instructions = { opts.additional_instructions, { "string", "nil" } },
    popup_type = {
      opts.popup_type,
      function(popup_type)
        return vim.tbl_contains({ "horizontal", "vertical", "popup" }, popup_type)
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

  -- Cargar el módulo dinámicamente según el nombre del proveedor
  local provider_name = M.options.provider
  local provider_config = M.options.providers[provider_name] or {}

  -- Inyectar hooks globales en la config del proveedor
  provider_config.hooks = M.options.hooks

  local ok, provider_module = pcall(require, "wtf.providers." .. provider_name)
  if ok and type(provider_module.setup) == "function" then
    provider_module.setup(provider_config)
  else
    vim.notify("WTF: No se pudo cargar el proveedor '" .. provider_name .. "'", vim.log.levels.ERROR)
  end
end

return M
