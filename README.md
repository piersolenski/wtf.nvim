# 🤯 wtf.nvim

A Neovim plugin to help you work out WTF that diagnostic means! 

wtf.nvim provides faster and more efficient ways of working with the buffer line's diagnostic messages by redirecting them to tools straight from Neovim. 

Works with any language that has LSP support in Neovim.

## ✨ Features

### AI powered diagnostic debugging

Use the power of ChatGPT to provide you with explanations *and* solutions of how to fix hints, warnings and errors, custom tailored to the code responsible for them.

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

Why spend time typing out error messages when you can open them in Google, Stack Overflow and more, directly from Neovim?

<table>
  <tr>
    <th>Google</th>
    <th>Duck Duck Go</th>
  </tr>
  <tr>
    <td>
      <img src="./screenshots/google-search.png" />
    </td>
    <td>
      <img src="./screenshots/google-search.png" />
    </td>
  </tr>
  <tr>
    <th>Stack Overflow</th>
    <th>Github Issues</th>
  </tr>
  <tr>
    <td>
      <img src="./screenshots/google-search.png" />
    </td>
    <td>
      <img src="./screenshots/google-search.png" />
    </td>
  </tr>
</table>

## 📦 Installation

In order to use the AI functionality, set the environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys) (the search functionality will still work without it).

Install the plugin with your preferred package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"piersolenski/wtf.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
 	event = "BufEnter",
  	opts = {},
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
			"gs",
			function()
				require("wtf").search()
			end,
			desc = "Search diagnostic with Google",
		},
	},
}
```

## ⚙️ Configuration

```lua
{
    -- Default AI popup type
    popup_type = "popup" | "horizontal" | "vertical",
    -- An alternative way to set your OpenAI api key
    openai_api_key = "sk-xxxxxxxxxxxxxx",
    -- ChatGPT Model
    openai_model_id = "gpt-3.5-turbo",
    -- Set your preferred language for the response
    language = "english",
    -- Any additional instructions
    additional_instructions = "Start the reply with 'OH HAI THERE'",
    -- Default search engine, can be overridden by passing an option to WtfSeatch 
    default_search_engine = "google" | "duck_duck_go" | "stack_overflow" | "github",
}
```


## 🚀 Usage

wtf.nvim works by sending the line's diagnostic messages along with contextual information (such as the code and filetype) to various differing sources you can configure.

Whenever you have an error in an LSP enabled environment, invoke a wtf.nvim command on that line:

| User Command | Purpose |
| -- | -- |
| `:Wtf <additional_instructions>` | Sends the current line along with all diagnostic messages to ChatGPT.
| `:WtfSearch <search_engine>` | Uses the specified search engine (or defaults to the one in the setup) to search for the **first** diagnostic. It will attempt to filter out unrelated strings specific to your local environment, such as file paths, for broader results. 

## 💡 Inspiration

- [Pretty TypeScript Errors](https://github.com/yoavbls/pretty-ts-errors)
- [backseat.nvim](https://github.com/james1236/backseat.nvim/) 
- [folke](https://github.com/folke/) 

