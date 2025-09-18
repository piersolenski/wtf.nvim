# 🤯 wtf.nvim

A Neovim plugin to help you work out *what the fudge* that diagnostic means **and** how to fix it!

`wtf.nvim` provides faster and more efficient ways of working with the buffer line's diagnostic messages using AI and web search. Works with any language that has [LSP](https://microsoft.github.io/language-server-protocol/) support in Neovim.

## ✨ Features

### Debugging diagnostics

Use the power of AI to provide you with explanations *and* solutions for how to fix diagnostics, custom tailored to the code responsible for them.

<https://github.com/piersolenski/wtf.nvim/assets/1285419/7572b101-664c-4069-aa45-84adc2678e25>

### Automagic fixing

Don't have time for reading or understanding because you're too busy vibe coding? Let AI solve your issues so you can get back to saving for that lambo.

<https://github.com/user-attachments/assets/e34a4f9f-3fbc-4f9e-b455-026abea65677>

### Search the web for answers

Why spend time copying and pasting, or worse yet, typing out diagnostic messages, when you can open a search for them in Google, Stack Overflow and more, directly from Neovim?

<https://github.com/piersolenski/wtf.nvim/assets/1285419/6697d9a5-c81c-4e54-b375-bbe900724077>

### Providers

Support for [Anthropic](https://www.anthropic.com), [Copilot](https://github.com/copilot), [DeepSeek](https://www.deepseek.com), [Gemini](https://gemini.google.com), [Grok](https://x.ai), [Ollama](https://ollama.com) and [OpenAI](https://openai.com).

### Multiple picker support

- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [Snacks.nvim](https://github.com/folke/snacks.nvim)
- [FZF-lua](https://github.com/ibhagwan/fzf-lua)

## 🔩 Installation

Install the plugin with your preferred package manager:

### lazy.nvim

```lua
{
  "piersolenski/wtf.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- Optional: For WtfGrepHistory (pick one)
    "nvim-telescope/telescope.nvim",
    -- "folke/snacks.nvim",
    -- "ibhagwan/fzf-lua",
  },
  opts = {},
  keys = {
    {
      "<leader>wd",
      mode = { "n", "x" },
      function()
        require("wtf").diagnose()
      end,
      desc = "Debug diagnostic with AI",
    },
    {
      "<leader>wf",
      mode = { "n", "x" },
      function()
        require("wtf").fix()
      end,
      desc = "Fix diagnostic with AI",
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
      "<leader>wp",
      function()
        require("wtf").pick_provider()
      end,
      desc = "Pick provider",
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

### packer.nvim

```lua
use({
  "piersolenski/wtf.nvim",
  config = function()
    require("wtf").setup()
  end,
  requires = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- Optional: For WtfGrepHistory (pick one)
    "nvim-telescope/telescope.nvim",
    -- "folke/snacks.nvim",
    -- "ibhagwan/fzf-lua",
  },
})
```

In order to use the AI functionality, you may need to set an environment variable for your provider of choice:

```sh
// Anthropic
export ANTHROPIC_API_KEY=your-api-key

// DeepSeek
export DEEPSEEK_API_KEY=your-api-key

// Gemini
export GEMINI_API_KEY=your-api-key

// Grok
export GROK_API_KEY=your-api-key

// OpenAI
export OPENAI_API_KEY=your-api-key
```

You can also set or override API keys in your config, but it is recommended to use environment variables.

## ⚙️ Configuration

```lua
{
  -- Directory for storing chat files
  chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/wtf/chats",
  -- Default AI popup type
  popup_type = "popup" | "horizontal" | "vertical",
  -- The default provider
  provider = "anthropic" | "copilot" | "deepseek" | "gemini" | "grok" | "ollama" | "openai",
  -- Configure providers
  providers = {
    anthropic = {
      -- An alternative way to set your API key
      api_key = "32lkj23sdjke223ksdlfk" | function() os.getenv("API_KEY") end,
      -- Your preferred model
      model_id = "claude-3-5-sonnet-20241022",
    },
  },
  -- Set your preferred language for the response
  language = "english",
  -- Any additional instructions
  additional_instructions = "Start the reply with 'OH HAI THERE'",
  -- Default search engine, can be overridden by passing an option to WtfSeatch
  search_engine = "google" | "duck_duck_go" | "stack_overflow" | "github" | "phind" | "perplexity",
  -- Picker for history search (telescope, snacks, or fzf-lua)
  picker = "telescope" | "snacks" | "fzf-lua",
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
| `:Wtf [instructions]` | Normal, Visual | Sends the code and diagnostic messages for a line or visual range to the provider. Additional instructions can also be specified, which might be useful if you want to offer extra context, such as `Wtf I'm using Node.js`.
| `:WtfFix [instructions]` | Normal, Visual | The same as `Wtf`, except instead of explaining the issue, it will attempt to fix it. Additional instructions can be specified, such as `WtfFix using camel casing`.
| `:WtfPickProvider` | Normal | Allows you to pick a different provider other than the one initially set in your config without restarting Vim.
| `:WtfSearch [search_engine]` | Normal | Uses a search engine (defaults to the one in the setup or Google if not provided) to search for the **first** diagnostic. It will attempt to filter out unrelated strings specific to your local environment, such as file paths, for broader results.
| `:WtfHistory` | Normal | Use the quickfix list to see your previous chats.
| `:WtfGrepHistory` | Normal | Grep your previous chats via your configured picker (Telescope, Snacks, or FZF-lua).

### Custom status hooks

You can add custom hooks to update your status line or other UI elements, for example, this code updates the status line colour to yellow whilst the request is in progress.

```lua
hooks = {
    request_started = function()
        vim.cmd("hi StatusLine ctermbg=NONE ctermfg=yellow")
    end,
    request_finished = function()
        vim.cmd("hi StatusLine ctermbg=NONE ctermfg=NONE")
    end,
},
```

### Lualine Status Component

There is a helper function `get_status` so that you can add a status component to [lualine](https://github.com/nvim-lualine/lualine.nvim).

```lua
local wtf = require("wtf")

require("lualine").setup({
  sections = {
    lualine_x = { wtf.get_status },
  },
})
```

## 🤓 About the author

As well as a passionate Vim enthusiast, I am a Full Stack Developer and Technical Lead from London, UK.

Whether it's to discuss a project, talk shop or just say hi, I'd love to hear from you!

- [Website](https://www.piersolenski.com/)
- [CodePen](https://codepen.io/piers)
- [LinkedIn](https://www.linkedin.com/in/piersolenski/)

<a href='https://ko-fi.com/piersolenski' target='_blank'>
  <img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' />
</a>
