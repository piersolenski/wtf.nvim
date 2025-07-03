---@type Wtf.Adapter
return {
  name = "ollama",
  url = "http://localhost:11434/v1/chat/completions",
  formatted_name = "Ollama",
  headers = {
    ["Content-Type"] = "application/json",
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
    }
  end,
  format_response = function(response)
    return response.choices[1].message.content
  end,
  format_error = function(response)
    return response[1].error.message
  end,
}
