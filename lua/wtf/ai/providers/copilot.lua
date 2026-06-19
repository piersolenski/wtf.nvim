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
    local config_path = vim.fs.joinpath(config_dir, "github-copilot", filename)
    if vim.fn.filereadable(config_path) == 1 then
      local lines = vim.fn.readfile(config_path)
      local config_data = vim.json.decode(table.concat(lines, "\n"))

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
  local done = false
  local result, request_err

  vim.net.request("https://api.github.com/copilot_internal/v2/token", {
    method = "GET",
    headers = {
      ["Authorization"] = "token " .. oauth_token,
      ["Accept"] = "application/json",
    },
  }, function(err, res)
    if err then
      request_err = err
    else
      local token_data = vim.json.decode(res.body)
      result = token_data.token
    end
    done = true
  end)

  vim.wait(30000, function()
    return done
  end)

  if request_err then
    error("Failed to get Copilot token: " .. request_err)
  end

  return result
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
    ["Editor-Version"] = "Neovim/"
      .. vim.version().major
      .. "."
      .. vim.version().minor
      .. "."
      .. vim.version().patch,
  },
  api_key = function()
    return get_copilot_token()
  end,
  format_request = function(data)
    return {
      model = data.model,
      max_tokens = data.max_tokens,
      temperature = data.temperature,
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
