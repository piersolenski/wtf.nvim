local get_diagnostics = require("wtf.get_diagnostics")
local get_filetype = require("wtf.get_filetype")
local gpt = require("wtf.gpt")
local display_popup = require("wtf.display_popup")

local function get_default_additional_instructions()
  return vim.g.wtf_default_additional_instructions or ""
end

local function get_language()
  return vim.g.wtf_language
end

local ai = function(additional_instructions)
  local diagnostics = get_diagnostics()
  local filetype = get_filetype()

  if diagnostics == nil then
    return print("No diagnostics found!")
  end

  local concatenatedDiagnostics = ""
  for _, diagnostic in ipairs(diagnostics) do
    concatenatedDiagnostics = concatenatedDiagnostics .. diagnostic.severity .. ": " .. diagnostic.message .. "\n"
  end

  local line = vim.fn.getline(".")

  local payload = "The coding language is "
    .. filetype
    .. ".\nThis is a list of the diagnostic messages: \n"
    .. concatenatedDiagnostics
    .. "This is the line of code for context: \n"
    .. line

  if get_default_additional_instructions() ~= "" then
    payload = payload .. "\n" .. get_default_additional_instructions()
  end

  if additional_instructions then
    payload = payload .. "\n" .. additional_instructions
  end

  if get_language() ~= "" and get_language() ~= "english" then
    payload = payload .. "\nRespond only in " .. get_language()
  end

  print("Generating explanation...")

  local messages = {
    {
      role = "system",
      content = [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages.
      When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting."]],
    },
    {
      role = "user",
      content = payload,
    },
  }

  gpt.request(messages, display_popup)
end

return ai
