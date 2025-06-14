return {
  name = "anthropic",
  formatted_name = "Anthropic",
  url = "https://api.anthropic.com/v1/messages",
  headers = {
    ["content-type"] = "application/json",
    ["x-api-key"] = "${api_key}",
    ["anthropic-version"] = "2023-06-01",
  },
  env = {
    api_key = "ANTHROPIC_API_KEY",
  },
  format_response = function(response)
    return response.content[1].text
  end,
}
