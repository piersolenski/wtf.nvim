# Plan: Remove nui.nvim dependency

## Decisions

- **Neovim minimum version:** 0.12+
- **Split windows:** `vim.api.nvim_open_win()` with `split = "right" | "below"`
- **Float window:** `vim.api.nvim_open_win()` with `relative = "editor"`
- **Padding:** Preserve 1-cell padding for `popup` type by shrinking the content area
- **Layout refresh:** Recalculate float geometry on `WinResized`; splits rely on the window manager

## 1. Replace `lua/wtf/ui/popup.lua`

Rewrite `M.show(message)` without any `require("nui.*")` calls.

### Helpers

```lua
local function split_string_by_line(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

local function create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].filetype = "markdown"
  return buf
end

local function apply_window_options(win)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].winhighlight = config.options.winhighlight
end
```

### `vertical` split

```lua
local win = vim.api.nvim_open_win(buf, true, {
  split = "right",
  width = math.floor(vim.o.columns * 0.5),
})
apply_window_options(win)
```

### `horizontal` split

```lua
local win = vim.api.nvim_open_win(buf, true, {
  split = "below",
  height = math.floor(vim.o.lines * 0.38),
})
apply_window_options(win)
```

### `popup` float

```lua
local padding = 1
local total_width = math.floor(vim.o.columns * 0.62)
local total_height = math.floor(vim.o.lines * 0.62)
local content_width = math.max(1, total_width - padding * 2)
local content_height = math.max(1, total_height - padding * 2)
local row = math.floor((vim.o.lines - total_height) / 2)
local col = math.floor((vim.o.columns - total_width) / 2)

local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  row = row,
  col = col,
  width = content_width,
  height = content_height,
  style = "minimal",
  border = "rounded",
  zindex = 50,
})
apply_window_options(win)
```

### Autocmds

- `BufLeave` for `popup` type: close the float with `vim.api.nvim_win_close(win, true)` and delete the scratch buffer.
- `WinResized`: only for `popup` type, recompute geometry and call `nvim_win_set_config(win, new_config)`.

### Return value

Keep returning an object with `bufnr` and `win` (or equivalent) so callers and tests that mock `wtf.ui.popup` continue to work.

```lua
return { bufnr = buf, win = win }
```

## 2. Update `tests/minimal_init.lua`

Remove nui cloning and runtime loading:

```diff
- local nui_dir = os.getenv("NUI_DIR") or "/tmp/nui.nvim"
- local nui_repo = "https://github.com/MunifTanjim/nui.nvim"
- clone_repo(nui_repo, nui_dir)
  vim.opt.rtp:append(".")
  vim.opt.rtp:append(plenary_dir)
- vim.opt.rtp:append(nui_dir)
  vim.cmd.runtime({ "plugin/plenary.vim" })
- vim.cmd.runtime({ "plugin/nui.vim" })
```

## 3. Update documentation

### `README.md`

Remove `"MunifTanjim/nui.nvim",` from the `dependencies` / `requires` blocks.

### `doc/wtf.nvim.txt`

Remove `"MunifTanjim/nui.nvim",` from the installation examples.

## 4. Version compatibility

- New minimum remains **Neovim 0.12**.
- `nvim_open_win` split windows require 0.10+, but this project already targets 0.12+.

## 5. Known tradeoffs

- **Manual layout math** replaces nui's `update_layout()`.
- **Padding is handled by shrinking the content area**, so the visible border sits 1 cell outside the text region. This matches the previous visual spacing.
- **No external UI framework** reduces dependencies and startup cost.

## 6. Implementation checklist

1. Rewrite `lua/wtf/ui/popup.lua` with native `nvim_open_win`.
2. Update `tests/minimal_init.lua` to remove nui.
3. Update `README.md` to remove nui.nvim dependency.
4. Update `doc/wtf.nvim.txt` to remove nui.nvim dependency.
5. Run `make lint`.
6. Run `make test`.
