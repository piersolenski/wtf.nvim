local telescope = require("telescope")
local telescope_picker = require("wtf.pickers.telescope")

local grep_history = function()
  telescope_picker.grep_history()
end

return telescope.register_extension({ exports = { grep_history = grep_history } })
