# wtf.nvim

Work out WTF that diagnostic is all about.

## Using

Install the plugin with your preferred package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```
{
	"piersolenski/wtf.nvim",
	dependencies = {
		"dpayne/CodeGPT.nvim",
	},
	keys = {
		{
			"gW",
			mode = { "n" },
			function()
				require("wtf").ai()
			end,
			desc = "Debug diagnostic with AI",
		},
		{
			mode = { "n" },
			"<leader>A",
			function()
				require("wtf").search()
			end,
			desc = "Search diagnostic with Google",
		},
	},
}
```
