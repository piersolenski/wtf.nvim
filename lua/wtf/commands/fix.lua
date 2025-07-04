local client = require("wtf.ai.client")
local hooks = require("wtf.hooks")
local notify = require("wtf.util.notify")
local process_diagnostics = require("wtf.util.process_diagnostics")

local function handle_response(response, line1, line2)
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
end

local function fix(opts)
  hooks.run_started_hook()

  local SYSTEM_PROMPT = "You are an expert coder with the express mission of fixing bugs with the help of LSP diagnostic messages."
    .. "Fix all the errors in the provided code and return only correct code without explanation, line numbers, or additional text."
    .. "Preserve original formatting, including spacing in forms of tabs or spaces, and new lines where it makes sense."

  local result = process_diagnostics(opts)
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return result.err
  end

  notify.ai_task_started("Fixing")

  -- Use coroutine since client function is async
  local co = coroutine.create(function()
    local response, client_err = client(SYSTEM_PROMPT, result.payload)

    if client_err then
      vim.notify(client_err, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return nil
    elseif response then
      handle_response(response, opts.line1, opts.line2)
      hooks.run_finished_hook()
    end

    return response
  end)

  coroutine.resume(co)
end

return fix
