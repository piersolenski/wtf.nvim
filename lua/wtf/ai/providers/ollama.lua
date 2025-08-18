---@type Wtf.Adapter
return {
  name = "ollama",
  url = "http://localhost:11434/v1/chat/completions",
  formatted_name = "Ollama",
  model_id = "gemma:latest",
  headers = {
    ["Content-Type"] = "application/json",
  },
  api_key = nil,
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
      temperature = data.temperature,
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response[1].error.message
  end,
}
