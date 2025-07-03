local config = require("wtf.config")
if vim.fn.has("nvim-0.7.0") == 0 then
  vim.api.nvim_err_writeln("wtf requires at least nvim-0.7.0.1")
  return
end

-- Automatically executed on startup
if vim.g.loaded_wtf then
  return
end
vim.g.loaded_wtf = true

local wtf = require("wtf")
local search_engines = require("wtf.sources.search_engines")

vim.api.nvim_create_user_command("Wtf", function(opts)
  wtf.diagnose({
    line1 = opts.line1,
    line2 = opts.line2,
    instructions = opts.args,
  })
end, {
  range = true,
  nargs = "*",
})

vim.api.nvim_create_user_command("WtfHistory", function()
  wtf.history()
end, {})

vim.api.nvim_create_user_command("WtfGrepHistory", function()
  wtf.grep_history()
end, {})

vim.api.nvim_create_user_command("WtfSearch", function(opts)
  wtf.search(opts.args)
end, {
  nargs = "?",
  complete = function(_, _, _)
    local completions = search_engines.get_completions()
    return completions
  end,
})
