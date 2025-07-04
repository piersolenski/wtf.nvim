local get_env_var = require("wtf.util.get_env_var")

---@type Wtf.Adapter
return {
  name = "anthropic",
  formatted_name = "Anthropic",
  url = "https://api.anthropic.com/v1/messages",
  model_id = "claude-3-5-sonnet-20241022",
  headers = {
    ["content-type"] = "application/json",
    ["x-api-key"] = "${api_key}",
    ["anthropic-version"] = "2023-06-01",
  },
  api_key = function()
    return get_env_var("ANTHROPIC_API_KEY")
  end,
  format_request = function(data)
    return {
      model = data.model,
      max_tokens = data.max_tokens,
      system = data.system,
      messages = {
        {
          role = "user",
          content = data.message,
        },
      },
    }
  end,
  format_response = function(response)
    return response.content[1].text
  end,
  format_error = function(response)
    return response.error.message
  end,
}
