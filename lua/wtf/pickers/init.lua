local config = require("wtf.config")

local M = {}

local picker_modules = {
  telescope = "wtf.pickers.telescope",
  snacks = "wtf.pickers.snacks",
  ["fzf-lua"] = "wtf.pickers.fzf",
}

function M.get_picker()
  local picker_name = config.options.picker
  local picker_module_name = picker_modules[picker_name]

  if not picker_module_name then
    error(string.format("Unknown picker: %s", picker_name))
  end

  local ok, picker = pcall(require, picker_module_name)
  if not ok then
    error(string.format("Failed to load picker module: %s", picker_module_name))
  end

  return picker
end

function M.grep_history()
  local picker = M.get_picker()

  if not picker.is_available() then
    local picker_name = config.options.picker
    local fallback_order = { "telescope", "fzf-lua", "snacks" }

    -- Try fallback pickers
    for _, fallback_name in ipairs(fallback_order) do
      if fallback_name ~= picker_name then
        local fallback_module_name = picker_modules[fallback_name]
        local ok, fallback_picker = pcall(require, fallback_module_name)
        if ok and fallback_picker.is_available() then
          vim.notify(
            string.format(
              "Configured picker '%s' not available, using '%s' instead",
              picker_name,
              fallback_name
            ),
            vim.log.levels.WARN
          )
          fallback_picker.grep_history()
          return
        end
      end
    end

    error(
      string.format(
        "No picker available. Please install one of: telescope.nvim, snacks.nvim, or fzf-lua"
      )
    )
  end

  picker.grep_history()
end

return M
