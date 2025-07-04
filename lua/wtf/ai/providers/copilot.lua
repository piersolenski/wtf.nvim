local curl = require("plenary.curl")
local Path = require("plenary.path")

local function get_oauth_token()
  local xdg_config = vim.fn.expand("$XDG_CONFIG_HOME")
  local config_dir

  if xdg_config and vim.fn.isdirectory(xdg_config) > 0 then
    config_dir = xdg_config
  elseif vim.fn.has("unix") == 1 then
    config_dir = vim.fn.expand("~/.config")
  else
    config_dir = vim.fn.expand("~/AppData/Local")
  end

  -- Check for copilot config files (hosts.json from copilot.lua, apps.json from copilot.vim)
  local config_files = { "hosts.json", "apps.json" }

  for _, filename in ipairs(config_files) do
    local config_path = Path:new(config_dir):joinpath("github-copilot", filename)
    if config_path:exists() then
      local config_data = vim.json.decode(config_path:read())

      -- Find GitHub entry and extract OAuth token
      for key, value in pairs(config_data) do
        if key:match("github.com") and value.oauth_token then
          return value.oauth_token
        end
      end
    end
  end

  error("No GitHub Copilot OAuth token found. Please setup copilot.lua or copilot.vim first.")
end

local function get_copilot_token()
  local oauth_token = get_oauth_token()

  -- Request GitHub API token using OAuth token
  local response = curl.get("https://api.github.com/copilot_internal/v2/token", {
    headers = {
      ["Authorization"] = "token " .. oauth_token,
      ["Accept"] = "application/json",
    },
    timeout = 30000,
  })

  if response.status == 200 then
    local token_data = vim.json.decode(response.body)
    return token_data.token
  else
    error("Failed to get Copilot token: " .. (response.body or "Unknown error"))
  end
end

---@type Wtf.Adapter
return {
  name = "copilot",
  formatted_name = "Copilot",
  url = "https://api.githubcopilot.com/chat/completions",
  model_id = "gpt-4o",
  headers = {
    Authorization = "Bearer ${api_key}",
    ["Content-Type"] = "application/json",
    ["Copilot-Integration-Id"] = "vscode-chat",
    ["Editor-Version"] = "Neovim/" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
  },
  api_key = function()
    return get_copilot_token()
  end,
  format_request = function(data)
    return {
      model = data.model,
      max_tokens = data.max_tokens,
      messages = {
        {
          role = "system",
          content = data.system,
        },
        {
          role = "user",
          content = data.message,
        },
      },
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response.error.message
  end,
}
