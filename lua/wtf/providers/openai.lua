---@type Wtf.Adapter
return {
  name = "openai",
  formatted_name = "OpenAI",
  base_url = "https://api.openai.com/v1",
  endpoint = "/chat/completions",
  headers = {
    ["Content-Type"] = "application/json",
    Authorization = "Bearer ${api_key}",
  },
  env = {
    api_key = "OPENAI_API_KEY",
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
          content = data.payload,
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
