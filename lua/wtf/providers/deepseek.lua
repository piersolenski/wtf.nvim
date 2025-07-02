---@type Wtf.Adapter
return {
  name = "deepseek",
  url = "https://api.deepseek.com/v1/chat/completions",
  formatted_name = "DeepSeek",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  env = {
    api_key = "DEEPSEEK_API_KEY",
  },
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
          content = data.messages,
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
    return response.error.message
  end,
}
