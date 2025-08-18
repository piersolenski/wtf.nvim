local client = require("wtf.ai.client")
local hooks = require("wtf.hooks")
local notify = require("wtf.util.notify")
local process_diagnostics = require("wtf.util.process_diagnostics")

local function handle_response(response, line1, line2)
  -- Clean the response by removing markdown code blocks if present
  local fixed_code = response:gsub("```[%w]*\n", ""):gsub("\n```", "")

  -- Remove carriage returns and then split the fixed code into lines
  local sanitized_code = fixed_code:gsub("\r", "")
  local fixed_lines = vim.split(sanitized_code, "\n")

  -- Replace the lines in the buffer
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, fixed_lines)

  vim.notify("Code fixed successfully!", vim.log.levels.INFO)
end

local function fix(opts)
  hooks.run_started_hook()

  local SYSTEM_PROMPT = "You are a code correction tool integrated into Neovim. "
    .. "Your ONLY task is to fix the LSP diagnostic errors in the provided code.\n\n"
    .. "CRITICAL RULES:\n"
    .. "1. Output ONLY the corrected code - nothing else\n"
    .. "2. NEVER include markdown formatting, code fences (```), or language tags\n"
    .. "3. NEVER add explanations, comments, or annotations\n"
    .. "4. NEVER add functionality beyond fixing the specific diagnostic issue\n"
    .. "5. Preserve EXACT formatting: indentation, spacing, line breaks, tabs vs spaces\n"
    .. "6. Fix ONLY the diagnostic issue - do not refactor or improve other code\n"
    .. "7. If code is partial, work with what's provided - do not complete missing parts\n\n"
    .. "Your output will directly replace the selected code in the buffer. "
    .. "Any extra text or formatting will corrupt the file."

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
      handle_response(response, result.line1, result.line2)
      hooks.run_finished_hook()
    end

    return response
  end)

  coroutine.resume(co)
end

return fix
