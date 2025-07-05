---@type Wtf.Adapter
return {
  name = "ollama",
  base_url = "http://localhost:11434",
  endpoint = "/api/chat",
  formatted_name = "Ollama (local)",
  headers = {
    ["Content-Type"] = "application/json",
  },
  env = {
    model = "tinyllama:latest",
  },
  format_request = function(data)
    return {
      model = data.model or "tinyllama:latest",
      messages = {
        {
          role = "system",
          content = data.system or "You are a helpful assistant.",
        },
        {
          role = "user",
          content = data.payload or "",
        },
      },
      stream = false,
      temperature = 0.7,
    }
  end,
  format_response = function(response)
    if response and response.message and response.message.content then
      return response.message.content
    end
    return nil
  end,
  format_error = function(response)
    if type(response) == "string" then
      return response
    elseif response and response.error then
      return response.error
    elseif response and response.message then
      return response.message
    else
      return "Unknown error using Ollama"
    end
  end,
}
