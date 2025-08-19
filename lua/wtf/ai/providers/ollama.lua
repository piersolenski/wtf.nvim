---@type Wtf.Adapter
return {
  name = "ollama",
  url = "http://localhost:11434/v1/chat/completions",
  formatted_name = "Ollama",
  model_id = vim.env.OLLAMA_MODEL_ID or "tinyllama",
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
    if type(response) == "table" then
      -- Ollama not installed or binary path issue
      if response.error and response.error.message then
        return response.error.message
      -- Ollama installed but API/model error
      elseif response[1] and response[1].error and response[1].error.message then
        return response[1].error.message
      end
    end
    return "Unknown error from Ollama"
  end,
}
