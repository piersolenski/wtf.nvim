local get_diagnostics = require("wtf.get_diagnostics")
local get_programming_language = require("wtf.utils.get_programming_language")
local search_engines = require("wtf.search_engines")
local remove_file_paths = require("wtf.utils.remove_file_paths")
local config = require("wtf.config")

local function get_open_command()
  local open_command
  if vim.fn.has("win32") == 1 then
    open_command = 'cmd /c start ""'
  elseif vim.fn.has("macunix") == 1 then
    open_command = "open"
  else
    open_command = "xdg-open"
  end

  return open_command
end

local function get_search_engine(search_engine)
  local target_engine = search_engine ~= "" and search_engine or config.options.search_engine
  local selected_engine = search_engines.sources[target_engine]

  if not selected_engine then
    return nil
  else
    return selected_engine
  end
end

local search = function(search_engine)
  local line = vim.fn.line(".")
  local diagnostics = get_diagnostics(line)
  local selected_search_engine = get_search_engine(search_engine)

  if selected_search_engine == nil then
    local message = "Invalid search engine"
    vim.notify(message, vim.log.levels.WARN)
    return message
  end

  if next(diagnostics) == nil then
    local message = "No diagnostics found!"
    vim.notify(message, vim.log.levels.WARN)
    return message
  end

  local programming_language = get_programming_language()

  local first_diagnostic = diagnostics[1]

  local clean_message = remove_file_paths(first_diagnostic.message)

  local search_string = programming_language .. " " .. first_diagnostic.severity .. " " .. clean_message

  local search_url = selected_search_engine .. search_string

  local open_command = get_open_command()

  local command = open_command .. " " .. '"' .. search_url .. '"'

  -- Open the URL using the appropriate command
  return vim.fn.system(command)
end
return search
