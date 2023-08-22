local get_diagnostics = require("wtf.get_diagnostics")
local get_filetype = require("wtf.get_filetype")

local function get_default_search_engine()
  return vim.g.wtf_default_search_engine
end

local function get_open_command()
  local open_command
  if vim.fn.has("win32") == 1 then
    open_command = "start"
  elseif vim.fn.has("macunix") == 1 then
    open_command = "open"
  else
    open_command = "xdg-open"
  end

  return open_command
end

local function remove_file_paths(inputString)
  local cleanedString = inputString:gsub("[A-Za-z0-9:/\\._%-]+[.][A-Za-z0-9]+", "")
  return cleanedString
end

local function get_search_engine(search_engine)
  local engines = {
    google = "https://www.google.com/search?q=",
    duck_duck_go = "https://duckduckgo.com/?q=",
    stack_overflow = "https://stackoverflow.com/search?q=",
    github = "https://github.com/search?type=issues&q=",
  }

  local target_engine = search_engine or get_default_search_engine()
  local selected_engine = engines[target_engine]

  if not selected_engine then
    print("Invalid search engine specified")
    return nil
  else
    return selected_engine
  end
end

local search = function(search_engine)
  local diagnostics = get_diagnostics()

  if diagnostics == nil then
    return print("No diagnostics found!")
  end

  local selected_search_engine = get_search_engine(search_engine)

  if selected_search_engine == nil then
    return nil
  end

  local filetype = get_filetype()

  local first_diagnostic = diagnostics[1]

  local clean_message = remove_file_paths(first_diagnostic.message)

  local search_string = filetype .. " " .. first_diagnostic.severity .. " " .. clean_message

  local search_url = selected_search_engine .. search_string

  local open_command = get_open_command()

  local command = open_command .. " " .. '"' .. search_url .. '"'

  -- Open the URL using the appropriate command
  vim.fn.system(command)
end

return search
