return {
  name = "anthropic",
  formatted_name = "Anthropic",
  base_url = "https://api.anthropic.com/v1",
  endpoint = "/messages",
  headers = {
    ["content-type"] = "application/json",
    ["x-api-key"] = "${api_key}",
    ["anthropic-version"] = "2023-06-01",
  },
  env = {
    api_key = "ANTHROPIC_API_KEY",
  },
  format_request_data = function(data)
    return {
      model = data.model,
      max_tokens = data.max_tokens,
      system = data.system,
      messages = {
        {
          role = "user",
          content = data.payload,
        },
      },
    }
  end,
  format_response = function(response)
    return response.content[1].text
  end,
}
