local client = require("wtf.ai.client")
local config = require("wtf.config")
local get_diagnostics = require("wtf.util.diagnostics")
local get_programming_language = require("wtf.util.get_programming_language")
local get_provider = require("wtf.util.get_provider")

local function get_content_between_lines(start_line, end_line)
  local lines = {}
  for line_num = start_line, end_line do
    local line = string.format("%d: %s", line_num, vim.fn.getline(line_num))
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

local fix = function(line1, line2, instructions)
  -- Return the user to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)

  local diagnostics = get_diagnostics(line1, line2)
  local programming_language = get_programming_language()

  if next(diagnostics) == nil then
    local message = "No diagnostics found!"
    vim.notify(message, vim.log.levels.WARN)
    return message
  end

  local concatenatedDiagnostics = ""
  for i, diagnostic in ipairs(diagnostics) do
    concatenatedDiagnostics = concatenatedDiagnostics
      .. i
      .. ". Issue "
      .. i
      .. "\n\t- Location: Line "
      .. diagnostic.line_number
      .. "\n\t- Severity: "
      .. diagnostic.severity
      .. "\n\t- Message: "
      .. diagnostic.message
      .. "\n"
  end

  local code = get_content_between_lines(line1, line2)

  local payload = "The programming language is "
    .. programming_language
    .. ".\nThis is a list of the diagnostic messages: \n"
    .. concatenatedDiagnostics

  payload = payload .. "This is the code for context: \n" .. "```\n" .. code .. "\n```"

  if instructions then
    payload = payload .. "\n" .. instructions
  end

  local provider = get_provider(config.options.provider)
  local model_id = config.options.providers[config.options.provider].model_id

  vim.notify("Fixing with " .. provider.formatted_name .. ": " .. model_id)

  local system = "You are an expert coder with the epxress mission of fixing bugs with the help of LSP diagnostic messages."
    .. "Fix all the errors in the provided code and return only correct code without explanation, line numbers, or additional text."
    .. "Preserve original formatting, including spacing in forms of tabs or spaces, and new lines where it makes sense."

  local co = coroutine.create(function()
    local response, err = client(provider, system, payload)

    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return nil
    end

    -- Apply the fix to the code using response
    if response then
      -- Clean the response by removing markdown code blocks if present
      local fixed_code = response:gsub("```[%w]*\n", ""):gsub("\n```", "")

      -- Split the fixed code into lines
      local fixed_lines = {}
      for line in fixed_code:gmatch("[^\r\n]+") do
        table.insert(fixed_lines, line)
      end

      -- Replace the lines in the buffer
      vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, fixed_lines)

      vim.notify("Code fixed successfully!", vim.log.levels.INFO)
    else
      vim.notify("No response received from AI provider", vim.log.levels.ERROR)
    end
  end)

  coroutine.resume(co)
end

return fix
