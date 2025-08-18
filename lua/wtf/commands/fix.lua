local client = require("wtf.ai.client")
local hooks = require("wtf.hooks")
local notify = require("wtf.util.notify")
local process_diagnostics = require("wtf.util.process_diagnostics")

--- Parse JSON response, with Tree-sitter fallback for markdown
--- @param response string The raw response from the LLM
--- @return table|nil Parsed JSON object or nil if parsing failed
local function parse_response(response)
  -- First try: Direct JSON parsing (remove common wrapping)
  local cleaned = response:gsub("^```json", ""):gsub("```$", ""):gsub("^```", "")
  local ok, json = pcall(vim.json.decode, cleaned)
  if ok and json then
    return json
  end

  -- Second try: Use Tree-sitter to extract code from markdown
  local parser = vim.treesitter.get_string_parser(response, "markdown")
  local syntax_tree = parser:parse()
  local root = syntax_tree[1]:root()

  local query = vim.treesitter.query.parse("markdown", [[(code_fence_content) @code]])

  for id, node in query:iter_captures(root, response, 0, -1) do
    if query.captures[id] == "code" then
      local node_text = vim.treesitter.get_node_text(node, response)
      -- Try to parse the extracted text as JSON
      ok, json = pcall(vim.json.decode, node_text)
      if ok and json then
        return json
      end
    end
  end

  -- Final fallback: Try to parse the raw response as JSON
  ok, json = pcall(vim.json.decode, response)
  if ok and json then
    return json
  end

  return nil
end

local function handle_response(response, line1, line2)
  local parsed = parse_response(response)
  
  if not parsed then
    vim.notify("Failed to parse AI response. Expected JSON format.", vim.log.levels.ERROR)
    return
  end

  if parsed.error then
    vim.notify("AI Error: " .. parsed.error, vim.log.levels.ERROR)
    return
  end

  if not parsed.code then
    vim.notify("No code in AI response", vim.log.levels.ERROR)
    return
  end

  -- Split the code into lines and apply to buffer
  local fixed_lines = vim.split(parsed.code, "\n")
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, fixed_lines)

  vim.notify("Code fixed successfully!", vim.log.levels.INFO)
end

local function fix(opts)
  hooks.run_started_hook()

  local SYSTEM_PROMPT = "You are a code correction tool integrated into Neovim. "
    .. "Your ONLY task is to fix the LSP diagnostic errors in the provided code.\n\n"
    .. "You MUST respond with valid JSON matching this exact schema:\n"
    .. "{\n"
    .. '  "code": "the corrected code here"\n'
    .. "}\n\n"
    .. "CRITICAL RULES:\n"
    .. "1. Output ONLY valid JSON - no other text before or after\n"
    .. "2. The 'code' field contains ONLY the fixed code\n"
    .. "3. NEVER add markdown, code fences, or explanations\n"
    .. "4. NEVER add functionality beyond fixing the diagnostic issue\n"
    .. "5. Preserve EXACT formatting: indentation, spacing, line breaks, tabs vs spaces\n"
    .. "6. Fix ONLY the diagnostic issue - do not refactor or improve other code\n"
    .. "7. If code is partial, work with what's provided - do not complete missing parts\n\n"
    .. "If you cannot fix the code, respond with:\n"
    .. '{\n'
    .. '  "error": "reason why the code cannot be fixed"\n'
    .. "}"

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
