-- Remove data that is either sensitive or irrelevant to the search
local function remove_user_data(inputString)
  local username = vim.env.USER or vim.env.USERNAME
  if not username or username == "" then
    local ok, pw = pcall(vim.loop.os_get_passwd)
    username = (ok and pw and pw.username) or ""
  end

  -- If we couldn't determine a username, don't attempt pattern replacement
  if username == "" then
    return inputString
  end

  -- Replace the username in the input string with '<user>'
  local path_pattern = "[/\\]Users[/\\]" .. vim.pesc(username)

  -- Replace the username in the input string only if it follows the /Users/ or \Users\ pattern
  local cleanedString = inputString:gsub(path_pattern, "/Users/<user>")

  return cleanedString
end

return remove_user_data
