# Plan: User-configurable per-provider temperature

## Goal

Allow users to override or omit the `temperature` parameter on a per-provider basis, so models that reject `temperature` (e.g. OpenAI `o1`/`o3` reasoning models) can be used without changing the plugin's default behavior for other models.

## Decisions

- **Backward compatibility:** Default behavior stays unchanged. `diagnose` still sends `0.5` and `fix` still sends `0.1` unless the user overrides it.
- **Override mechanism:** Add an optional `temperature` field to each provider's config.
  - `number` — use this value instead of the command default.
  - `false` — explicitly omit `temperature` from the request body.
  - `nil` or missing — use the command default (`0.5` for diagnose, `0.1` for fix).
- **Lua nil limitation:** Because `temperature = nil` is indistinguishable from a missing key after `vim.tbl_deep_extend`, `false` is used as the explicit "omit" sentinel.

## 1. Update the adapter type

### `lua/wtf/ai/providers/init.lua`

Add an optional `temperature` field to the `Wtf.Adapter` class definition:

```lua
---@field temperature number | false | nil Optional override; false omits temperature from requests
```

## 2. Compute effective temperature in the client

### `lua/wtf/ai/client.lua`

Before calling `provider.format_request`, resolve the final temperature value:

```lua
local function resolve_temperature(provider, default_temperature)
  if provider.temperature == false then
    return nil -- explicitly omitted
  end

  if type(provider.temperature) == "number" then
    return provider.temperature
  end

  return default_temperature
end
```

Then pass the resolved value:

```lua
local effective_temperature = resolve_temperature(provider, temperature)

local request_data = provider.format_request({
  model = model_id,
  max_tokens = DEFAULT_MAX_TOKENS,
  system = system,
  message = message,
  temperature = effective_temperature,
})
```

## 3. Conditionally include temperature in every provider

### All files under `lua/wtf/ai/providers/*.lua`

Update each `format_request` function to only include `temperature` when it is non-nil.

Example for `lua/wtf/ai/providers/openai.lua`:

```lua
format_request = function(data)
  local body = {
    model = data.model,
    messages = {
      { role = "system", content = data.system },
      { role = "user", content = data.message },
    },
  }

  if data.temperature ~= nil then
    body.temperature = data.temperature
  end

  return body
end
```

Apply the same pattern to:

- `lua/wtf/ai/providers/anthropic.lua`
- `lua/wtf/ai/providers/copilot.lua`
- `lua/wtf/ai/providers/deepseek.lua`
- `lua/wtf/ai/providers/gemini.lua`
- `lua/wtf/ai/providers/grok.lua`
- `lua/wtf/ai/providers/ollama.lua`
- `lua/wtf/ai/providers/opencode.lua`
- `lua/wtf/ai/providers/openai.lua`

## 4. Document the new provider option

### `README.md`

Update the provider configuration example:

```lua
providers = {
  openai = {
    model_id = "gpt-4o",
    -- Use a custom temperature (default is 0.5 for diagnose, 0.1 for fix)
    temperature = 0.7,
    -- Set to false to omit temperature entirely for models that don't support it
    -- temperature = false,
  },
}
```

### `doc/wtf.nvim.txt`

Mirror the same documentation in the Vim help file.

## 5. Validation

### `lua/wtf/validation.lua`

Optionally validate that `provider.temperature` is one of `number`, `false`, or `nil` when present. This catches typos early.

```lua
local function validate_temperature(value)
  return value == nil or value == false or type(value) == "number"
end
```

## 6. Tests

### `tests/wtf/providers_spec.lua`

Add unit-style tests for provider request formatting that don't require API keys. For each provider:

1. Default behavior includes `temperature` when a numeric value is passed.
2. `temperature = false` causes the key to be absent from the encoded request body.
3. `temperature = <number>` uses the configured value instead of the default.

Example assertion:

```lua
local openai = require("wtf.ai.providers.openai")
local request = openai.format_request({
  model = "o3-mini",
  system = "sys",
  message = "msg",
  max_tokens = 4096,
  temperature = nil,
})
assert.is_nil(request.temperature)
```

## 7. Implementation checklist

1. `lua/wtf/ai/providers/init.lua` — document `temperature` field on `Wtf.Adapter`.
2. `lua/wtf/ai/client.lua` — add `resolve_temperature` helper and pass effective value.
3. `lua/wtf/ai/providers/*.lua` — conditionally include `temperature` in each `format_request`.
4. `lua/wtf/validation.lua` — optionally validate `provider.temperature` type.
5. `README.md` — document the new `temperature` option.
6. `doc/wtf.nvim.txt` — document the new `temperature` option.
7. `tests/wtf/providers_spec.lua` — add formatting tests.
8. Run `make lint` and `make test`.

## 8. Example user config

```lua
require("wtf").setup({
  provider = "openai",
  providers = {
    openai = {
      model_id = "o3-mini",
      temperature = false, -- o3-mini does not support temperature
    },
    anthropic = {
      model_id = "claude-sonnet-4-6",
      temperature = 0.7, -- override default
    },
  },
})
```
