local M = {}

M.name = "grok"
M.url = "https://api.x.ai/v1/chat/completions"
M.env_api_key_name = "GROK_API_KEY"

M.format_request_data = function(data)
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
  }
end

M.format_response = function(response)
  return response.choices[1].message.content
end

return M
