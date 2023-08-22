if vim.fn.has("nvim-0.7.0") == 0 then
	vim.api.nvim_err_writeln("wtf requires at least nvim-0.7.0.1")
	return
end

-- Automatically executed on startup
if vim.g.loaded_wtf then
	return
end
vim.g.loaded_wtf = true

require("wtf").setup()

vim.api.nvim_create_user_command("Wtf", function(opts)
	require("wtf").ai(opts.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("WtfSearch", function(opts)
	require("wtf").search(opts.args)
end, { nargs = "?" })
