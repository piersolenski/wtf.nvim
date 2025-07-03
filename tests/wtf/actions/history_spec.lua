local plugin = require("wtf")
local save_chat = require("wtf.util.save_chat")

describe("History", function()
  local chat_dir = "/tmp/wtf-chats"

  before_each(function()
    vim.fn.mkdir(chat_dir, "p")
    plugin.setup({
      chat_dir = chat_dir,
    })
  end)

  after_each(function()
    vim.fn.system("rm -rf " .. chat_dir)
  end)

  it("is empty by default", function()
    plugin.history()
    local quickfix_list = vim.fn.getqflist()

    assert.are.equal(0, #quickfix_list)
  end)

  it("has one item after a chat has been saved", function()
    save_chat("An example of a chat response")

    plugin.history()
    local quickfix_list = vim.fn.getqflist()

    assert.are.equal(1, #quickfix_list)
  end)
end)
