# wtf.nvim

A Neovim plugin to help you work out WTF that diagnostic means! 

wtf.nvim uses the power of AI to provide you with both explanations and solutions of how to fix LSP hints, warnings and errors, custom tailored to the code responsible for them. 

wtf.nvim works by sending the line diagnostic messages, along with the offending code for context, directly to ChatGPT. This kkkkkkk more accurate solutions leading to quicker fixes. For those times that AI fails you, you can also search multiple sources on the web. Works with any language that has LSP support in Neovim.

## Functionality

### AI powered diagnostic debugging

<table>
  <tr>
    <th></th>
    <th>Before</th>
    <th>After</th>
  </tr>
  <tr>
    <td valign="middle">
     Python
    </td>
    <td>
      <img src="./screenshots/python-before.png" />
    </td>
    <td>
      <img src="./screenshots/python-after.png" />
    </td>
  </tr>
  <tr>
    <td valign="middle">
     Typescript
    </td>
    <td>
      <img src="./screenshots/typescript-before.png" />
    </td>
    <td>
      <img src="./screenshots/typescript-after.png" />
    </td>
  </tr>
</table>

### Search the web for answers 

![Google](./screenshots/google-search.png)

## Installation

If you want to use AI functionality, set the environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys).

Search functionality doesn't require it.

Install the plugin with your preferred package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"piersolenski/wtf.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
  	opts = {
        -- Default AI popup type
		popup_type = "popup" | "horizontal" | "vertical",
        -- An alternative way to set your OpenAI api key
        openai_api_key = "sk-xxxxxxxxxxxxxx",
        --gpt-4 (If you do not have access to a model, it says "The model does not exist")
        openai_model_id = "gpt-3.5-turbo",
        -- Set your preferred language for the response
        language = "english",
        -- Any additional instructions
        additional_instructions = "Start the reply with 'OH HAI THERE'",
        -- Default search engine
        default_search_engine = "google" | "duck_duck_go" | "stack_overflow" | "github",

	},
	keys = {
		{
			"gw",
			mode = { "n" },
			function()
				require("wtf").ai()
			end,
			desc = "Debug diagnostic with AI",
		},
		{
			mode = { "n" },
			"gW",
			function()
				require("wtf").search()
			end,
			desc = "Search diagnostic with Google",
		},
	},
}
```

## Usage

Whenever you have an error in an LSP enabled environment, invoke a wtf.nvim command on that line:

| User Command | Purpose |
| -- | -- |
| `:Wtf <additional_instructions>` | Sends the current line along with all diagnostic messages to ChatGPT
| `:WtfSearch <search_engine>` | Uses the specified search engine (or defaults to the one in the setup) to search for the **first** diagnostic. It will attempt to filter out unrelated strings specific to your local environment, such as file paths, for broader results. 

## Inspiration

- [Pretty TypeScript Errors](https://github.com/yoavbls/pretty-ts-errors)
- [backseat.nvim](https://github.com/james1236/backseat.nvim/) 

