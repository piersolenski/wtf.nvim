return {
  name = "grok",
  base_url = "https://api.x.ai/v1",
  endpoint = "/chat/completions",
  formatted_name = "Grok",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  env = {
    api_key = "XAI_API_KEY",
  },
  format_request_data = function(data)
    return {
      model = data.model,
      messages = {
        {
          role = "system",
          content = data.system,
        },
        {
          role = "user",
          content = data.payload,
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
