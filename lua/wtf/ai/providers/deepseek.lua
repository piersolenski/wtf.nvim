local get_env_var = require("wtf.util.get_env_var")

---@type Wtf.Adapter
return {
  name = "deepseek",
  url = "https://api.deepseek.com/v1/chat/completions",
  formatted_name = "DeepSeek",
  model_id = "deepseek-reasoner",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  api_key = function()
    return get_env_var("DEEPSEEK_API_KEY")
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
      temperature = data.temperature,
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response.error.message
  end,
}
