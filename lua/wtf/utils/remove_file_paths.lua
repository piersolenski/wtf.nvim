-- Remove file paths that are more than one directory deep
local function remove_file_paths(inputString)
  local cleanedString = inputString:gsub("[A-Za-z0-9:/\\._%-]+[.][A-Za-z0-9]+", "")
  cleanedString = cleanedString:gsub("[A-Za-z0-9:/\\._%-]+[/\\][A-Za-z0-9:/\\._%-]+[.][A-Za-z0-9]+", "")
  return cleanedString
end

return remove_file_paths
