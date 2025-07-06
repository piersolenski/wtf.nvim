local get_env_var = require("wtf.util.get_env_var")

---@type Wtf.Adapter
return {
  name = "grok",
  url = "https://api.x.ai/v1/chat/completions",
  formatted_name = "Grok",
  model_id = "grok-3-mini",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  api_key = function()
    return get_env_var("GROK_API_KEY")
  end,
  format_request = function(data)
    return {
      model = data.model,
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
      max_tokens = data.max_tokens,
      stream = false,
      temperature = 0.7,
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response.error
  end,
}
