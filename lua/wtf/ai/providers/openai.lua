local get_env_var = require("wtf.util.get_env_var")

---@type Wtf.Adapter
return {
  name = "openai",
  formatted_name = "OpenAI",
  url = "https://api.openai.com/v1/chat/completions",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  api_key = function()
    return get_env_var("OPENAI_API_KEY")
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
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response.error.message
  end,
}
