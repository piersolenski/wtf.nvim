local function clone_repo(repo_url, dest_dir)
  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.system({ "git", "clone", repo_url, dest_dir })
  end
end

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local nui_dir = os.getenv("NUI_DIR") or "/tmp/nui.nvim"

local plenary_repo = "https://github.com/nvim-lua/plenary.nvim"
local nui_repo = "https://github.com/MunifTanjim/nui.nvim"

clone_repo(plenary_repo, plenary_dir)
clone_repo(nui_repo, nui_dir)

vim.opt.swapfile = false

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(nui_dir)

vim.cmd.runtime({ "plugin/plenary.vim" })
vim.cmd.runtime({ "plugin/nui.vim" })
require("plenary.busted")
