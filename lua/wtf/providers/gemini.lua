---@type Wtf.Adapter
return {
  name = "gemini",
  url = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
  formatted_name = "Gemini",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  env = {
    api_key = "GEMINI_API_KEY",
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
    return response[1].error.message
  end,
}
