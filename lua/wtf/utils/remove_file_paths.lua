-- Remove data that is either sensitive or irrelevant to the search
local function remove_user_data(inputString)
  return inputString
  -- local username = vim.fn.system("whoami"):gsub("%s+", "")
  --
  -- -- Replace the username in the input string with '<user>'
  -- local path_pattern = "[/\\]Users[/\\]" .. username
  --
  -- -- Replace the username in the input string only if it follows the /Users/ or \Users\ pattern
  -- local cleanedString = inputString:gsub(path_pattern, "/Users/<user>")
  --
  -- return cleanedString
end

return remove_user_data
