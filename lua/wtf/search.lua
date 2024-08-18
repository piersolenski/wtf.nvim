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

local open_search_url = function(search_engine, programming_language, severity, message)
  local search_string = programming_language .. " " .. severity .. " " .. message

  local search_url = search_engine .. search_string

  local open_command = get_open_command()

  local command = open_command .. " " .. '"' .. search_url .. '"'

  -- Open the URL using the appropriate command
  return vim.fn.system(command)
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

  -- Let user select a diagnostic to search if multiple are present
  if #diagnostics > 1 then
    local opts = {
      prompt = "Choose a diagnostic:",
      format_item = function(item)
        return remove_file_paths(item.message)
      end,
    }
    vim.ui.select(diagnostics, opts, function(chosen_diagnostic)
      if chosen_diagnostic then
        return open_search_url(
          selected_search_engine,
          programming_language,
          chosen_diagnostic.severity,
          chosen_diagnostic.message
        )
      end
    end)
  else
    local diagnostic = diagnostics[1]
    local message = remove_file_paths(diagnostic.message)
    return open_search_url(selected_search_engine, programming_language, diagnostic.severity, message)
  end
end
return search
