# 🤯 wtf.nvim

A Neovim plugin to help you work out *what the fudge* that diagnostic means **and** how to fix it!

`wtf.nvim` provides faster and more efficient ways of working with the buffer line's diagnostic messages by redirecting them to your favourite resources straight from Neovim. 
Works with any language that has [LSP](https://microsoft.github.io/language-server-protocol/) support in Neovim.

## ✨ Features

### AI powered diagnostic debugging

Use the power of [ChatGPT](https://openai.com/blog/chatgpt) to provide you with explanations *and* solutions for how to fix diagnostics, custom tailored to the code responsible for them.

https://github.com/piersolenski/wtf.nvim/assets/1285419/7572b101-664c-4069-aa45-84adc2678e25

### Search the web for answers 

Why spend time copying and pasting, or worse yet, typing out diagnostic messages, when you can open a search for them in Google, Stack Overflow and more, directly from Neovim?

https://github.com/piersolenski/wtf.nvim/assets/1285419/6697d9a5-c81c-4e54-b375-bbe900724077

## 🔩 Installation

In order to use the AI functionality, set the environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys) (the search functionality will still work without it).

Install the plugin with your preferred package manager:

```lua
-- Packer
use({
  "piersolenski/wtf.nvim",
    config = function()
      require("wtf").setup()
    end,
    requires = {
      "MunifTanjim/nui.nvim",
    }
})

-- Lazy
{
	"piersolenski/wtf.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
  	opts = {},
	keys = {
		{
			"<leader>wa",
			mode = { "n", "x" },
			function()
				require("wtf").ai()
			end,
			desc = "Debug diagnostic with AI",
		},
		{
			mode = { "n" },
			"<leader>ws",
			function()
				require("wtf").search()
			end,
			desc = "Search diagnostic with Google",
		},
		{
			mode = { "n" },
			"<leader>wh",
			function()
				require("wtf").history()
			end,
			desc = "Populate the quickfix list with previous chat history",
		},
		{
			mode = { "n" },
			"<leader>wg",
			function()
				require("wtf").grep_history()
			end,
			desc = "Grep previous chat history with Telescope",
		},
	},
}
```

## ⚙️ Configuration

```lua
{
   	-- Directory for storing chat files 
    chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/wtf/chats",
    -- Default AI popup type
    popup_type = "popup" | "horizontal" | "vertical",
    -- An alternative way to set your API key
    openai_api_key = "sk-xxxxxxxxxxxxxx",
    -- ChatGPT Model
    openai_model_id = "gpt-3.5-turbo",
    -- Configure base url to work over proxy or with other api-compatable services
    openai_base_url = "https://api.openai.com",
    -- Send code as well as diagnostics
    context = true,
    -- Set your preferred language for the response
    language = "english",
    -- Any additional instructions
    additional_instructions = "Start the reply with 'OH HAI THERE'",
    -- Default search engine, can be overridden by passing an option to WtfSeatch
    search_engine = "google" | "duck_duck_go" | "stack_overflow" | "github" | "phind" | "perplexity",
    -- Callbacks
    hooks = {
        request_started = nil,
        request_finished = nil,
    },
    -- Add custom colours
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
}
```

## 🚀 Usage

`wtf.nvim` works by sending the line's diagnostic messages along with contextual information (such as the offending code, file type and severity level) to various sources you can configure.

To use it, whenever you have an hint, warning or error in an LSP enabled environment, invoke one of the commands:

| Command | Modes | Description |
| -- | -- | -- |
| `:Wtf [additional_instructions]` | Normal, Visual | Sends the diagnostic messages for a line or visual range to ChatGPT, along with the code if the context has been set to `true`. Additional instructions can also be specified, which might be useful if you want to refine the response further.
| `:WtfSearch [search_engine]` | Normal | Uses a search engine (defaults to the one in the setup or Google if not provided) to search for the **first** diagnostic. It will attempt to filter out unrelated strings specific to your local environment, such as file paths, for broader results. 
| `:WtfHistory` | Normal | Use the quickfix list to see your previous chats. 
| `:WtfGrepHistory` | Normal | Grep your previous chats via [Telescope](https://github.com/nvim-telescope/telescope.nvim!). 


### Custom status hooks

You can add custom hooks to update your status line or other UI elements, for example, this code updates the status line colour to yellow whilst the request is in progress.

```lua
hooks = {
    request_started = function()
        vim.cmd("hi StatusLine ctermbg=NONE ctermfg=yellow")
    end,
    request_finished = vim.schedule_wrap(function()
        vim.cmd("hi StatusLine ctermbg=NONE ctermfg=NONE")
    end),
},
```

### Lualine Status Component

There is a helper function `get_status` so that you can add a status component to [lualine](https://github.com/nvim-lualine/lualine.nvim).

```lua
local wtf = require("wtf")

require('lualine').setup({
    sections = {
        lualine_x = { wtf.get_status },
    }
})
```

## 💡 Inspiration

- [Pretty TypeScript Errors](https://github.com/yoavbls/pretty-ts-errors)
- [backseat.nvim](https://github.com/james1236/backseat.nvim/) 
- [CodeGPT.nvim](https://github.com/dpayne/CodeGPT.nvim) 

## 🤓 About the author

As well as Vim enthusiast, I am a Front-End Developer and Technical Lead from London, UK.

Whether it's to discuss a project, talk shop or just say hi, I'd love to hear from you!

- [Website](https://www.piersolenski.com/)
- [CodePen](https://codepen.io/piers)
- [LinkedIn](https://www.linkedin.com/in/piersolenski/)

<a href='https://ko-fi.com/piersolenski' target='_blank'>
    <img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' />
</a>
