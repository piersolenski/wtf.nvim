# Plan: Remove plenary.nvim dependency

## Decisions

- **Neovim minimum version:** 0.12+
- **HTTP replacement:** `vim.net.request()` (Option B)
- **Test runner:** Replace `plenary.busted` with a custom luassert-based runner
- **Path/file I/O:** Native `vim.fs` / `vim.fn`

## 1. HTTP: replace `plenary.curl` with `vim.net.request()`

Help docs: `:help vim.net.request()`

### `lua/wtf/ai/client.lua`

Replace the `curl.post` call in `make_http_request` with `vim.net.request("POST", ...)`:

```lua
vim.net.request("POST", url, {
  headers = headers,
  body = vim.json.encode(request_data),
}, function(err, res)
  vim.schedule(function()
    if err then
      -- vim.net.request gives us only a curl error string on 4xx/5xx.
      -- Preserve the existing response shape so process_response keeps working.
      coroutine.resume(co, { status = 400, body = err })
    else
      coroutine.resume(co, { status = 200, body = res.body })
    end
  end)
end)
```

`process_response` stays essentially the same; it will decode `res.body` on success and return `"Bad or no response from API"` on HTTP errors.

### `lua/wtf/ai/providers/copilot.lua`

Replace the synchronous `curl.get` with `vim.net.request` wrapped in `vim.wait`:

```lua
local done = false
local result, request_err

vim.net.request("GET", "https://api.github.com/copilot_internal/v2/token", {
  headers = {
    ["Authorization"] = "token " .. oauth_token,
    ["Accept"] = "application/json",
  },
}, function(err, res)
  if err then
    request_err = err
  else
    local token_data = vim.json.decode(res.body)
    result = token_data.token
  end
  done = true
end)

vim.wait(30000, function() return done end)

if request_err then
  error("Failed to get Copilot token: " .. request_err)
end
return result
```

`vim.net.request()` has no built-in `timeout` option, so `vim.wait` caps the wait.

## 2. Path / file I/O: replace `plenary.path` with built-ins

Help docs: `:help vim.fs`, `:help vim.fs.joinpath()`, `:help filereadable()`, `:help readfile()`

In `lua/wtf/ai/providers/copilot.lua`, replace the Copilot config file reading:

```lua
-- before
local config_path = Path:new(config_dir):joinpath("github-copilot", filename)
if config_path:exists() then
  local config_data = vim.json.decode(config_path:read())
  ...
end

-- after
local config_path = vim.fs.joinpath(config_dir, "github-copilot", filename)
if vim.fn.filereadable(config_path) == 1 then
  local lines = vim.fn.readfile(config_path)
  local config_data = vim.json.decode(table.concat(lines, "\n"))
  ...
end
```

## 3. Tests: remove `plenary.busted` entirely

Add `luassert` as a dev dependency (via LuaRocks) and write a minimal in-Neovim runner in `tests/minimal_init.lua`.

### Dev dependency

```bash
luarocks --lua-version 5.1 install luassert
```

### `Makefile`

```makefile
test:
	@eval "$$(luarocks path --bin)" && \
	nvim --headless --noplugin -u tests/minimal_init.lua -c "lua RunWtfTests('tests')"
```

### `tests/minimal_init.lua`

Rough structure:

- Set `rtp` to include the plugin and `nui.nvim`.
- Load the nui plugin.
- Pull in `LUA_PATH` / `LUA_CPATH` from the environment.
- Set `_G.assert = require("luassert")`.
- Implement lightweight `describe`, `it` (sync + async `done`), `before_each`, `after_each`, `pending`.
- Implement `RunWtfTests(dir)` that globs `*_spec.lua`, runs them, prints a summary, and exits via `vim.cmd("0cq")` / `vim.cmd("1cq")`.

The tests use `require("luassert.mock")`, `require("luassert.spy")`, and async `done`, so the runner must support those patterns.

## 4. Documentation and packaging

- `README.md`: remove `nvim-lua/plenary.nvim`; add Neovim ≥ 0.12 requirement.
- `doc/wtf.nvim.txt`: same changes.
- `Makefile`: update test command.
- `.github/workflows/test.yml`: change matrix to `["v0.12.0", "nightly"]"; install `luassert` via LuaRocks.
- `.github/workflows/check-models.yml`: remove the plenary clone step.

## 5. Version compatibility

- New minimum: **Neovim 0.12**.
- `vim.net.request()` requires 0.12 (`:help news-0.12`).

## 6. Known tradeoffs

- **HTTP 4xx/5xx bodies are lost** because `vim.net.request()` uses `curl --fail` internally.
- **No request timeout option** in `vim.net.request()`; mitigated with `vim.wait`.
- **`curl` is still required** on the system.
- **Custom test runner** must be maintained.

## 7. Implementation checklist

1. `lua/wtf/ai/client.lua` — switch POST to `vim.net.request`.
2. `lua/wtf/ai/providers/copilot.lua` — switch GET to `vim.net.request`; replace `plenary.path`.
3. `tests/minimal_init.lua` — rewrite as luassert-based custom runner.
4. `Makefile` — update test command.
5. `README.md` / `doc/wtf.nvim.txt` — remove plenary, add 0.12 requirement.
6. `.github/workflows/test.yml` — bump matrix, install luassert.
7. `.github/workflows/check-models.yml` — remove plenary clone.
8. Run `make lint` and `make test`.
