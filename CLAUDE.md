# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

wtf.nvim is a Neovim plugin that helps debug LSP diagnostic messages using AI and web search. It sends diagnostic messages along with code context to various AI providers (Anthropic, OpenAI, DeepSeek, Gemini, Grok, Ollama, Copilot) to explain errors and suggest fixes.

## Development Commands

### Testing
```bash
# Run all tests (includes Ollama setup if available)
make test

# Run tests with a specific Ollama model
OLLAMA_MODEL_ID=tinyllama make test

# Test initialization file
TESTS_INIT=tests/minimal_init.lua
```

Tests use plenary.nvim's test framework and are located in `tests/`.

### Linting and Formatting
```bash
# Lint Lua code
make lint

# Format code with stylua
make format
```

## Architecture

### Core Flow

The plugin follows this execution path:
1. **Commands** (`lua/wtf/commands/`) - Entry points for user actions (diagnose, fix, search, history)
2. **Process Diagnostics** (`lua/wtf/util/process_diagnostics.lua`) - Extracts LSP diagnostics and code context from the buffer
3. **AI Client** (`lua/wtf/ai/client.lua`) - Generic HTTP client that works with all providers
4. **Providers** (`lua/wtf/ai/providers/`) - Provider-specific adapters that format requests/responses
5. **UI Popup** (`lua/wtf/ui/popup.lua`) - Displays results using nui.nvim (popup, horizontal, or vertical split)

### Provider System

All AI providers implement the `Wtf.Adapter` interface:
- `name`: Provider identifier (e.g., "openai")
- `formatted_name`: Display name
- `url`: API endpoint
- `headers`: HTTP headers with `${api_key}` placeholder
- `api_key`: Optional hardcoded key or function
- `format_request(data)`: Converts generic request to provider format
- `format_response(response)`: Extracts text from provider response
- `format_error(response)`: Formats error messages

The client (`lua/wtf/ai/client.lua`) uses coroutines for async HTTP requests via plenary.curl.

### Key Components

- **Config** (`lua/wtf/config.lua`) - Merges user options with provider defaults, validates configuration
- **Diagnostics** (`lua/wtf/util/diagnostics.lua`) - Fetches LSP diagnostics for line ranges
- **Hooks** (`lua/wtf/hooks.lua`) - User callbacks for request lifecycle (request_started/finished)
- **Pickers** (`lua/wtf/pickers/`) - Telescope/Snacks/FZF-lua integrations for history search
- **Search Engines** (`lua/wtf/sources/search_engines.lua`) - Web search URL builders

### Chat History

Chats are saved to `vim.fn.stdpath("data")/wtf/chats/` as markdown files with format:
- Filename: `{timestamp}_{first_diagnostic_message}.md`
- Content: Includes language, diagnostics, code, and AI response

## Testing Notes

- `tests/minimal_init.lua` - Minimal Neovim config for testing
- `tests/wtf/helpers.lua` - Test utilities
- Tests mock AI responses since they require API keys
- Ollama tests run automatically if Ollama can be installed/started

## Important Patterns

### Adding a New Provider

1. Create `lua/wtf/ai/providers/newprovider.lua` implementing the `Wtf.Adapter` interface
2. Add to `lua/wtf/ai/providers/init.lua`
3. Set default model_id in the provider file
4. Document environment variable (if needed) in README.md

### API Key Resolution

API keys are resolved in this order:
1. `api_key` in user config (can be string or function)
2. Environment variable (provider-specific, e.g., `OPENAI_API_KEY`)
3. Error if not found

The `get_api_key` util handles both string and function types.

### Popup Types

Three display modes configured via `popup_type`:
- `"popup"` - Centered floating window (62% width/height)
- `"horizontal"` - Bottom split (38% height)
- `"vertical"` - Right split (50% width)

All use nui.nvim's Popup/Split components and render markdown.
