# wtf.nvim

Work out WTF that diagnostic is all about. Helps debug and explain what errors or warnings mean with the context of the surrounding code.

## Functionality

* Use AI to get answers in popup window
* Search the web for answers 

## Using

If you want to use AI functionality, set the environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys).

Install the plugin with your preferred package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```
{
	"piersolenski/wtf.nvim",
	dependencies = {
		"dpayne/CodeGPT.nvim", -- Optional, if you want to use AI
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
