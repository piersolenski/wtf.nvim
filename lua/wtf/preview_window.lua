local Popup = require("nui.popup")

local preview_window = Popup:extend("preview_window")

function preview_window:init(options)
	options = vim.tbl_deep_extend("keep", options or {}, {
		position = "50%",
		size = {
			width = "62%",
			height = "62%",
		},
		padding = { 1, 1, 1, 1 },
		enter = true,
		focusable = true,
		zindex = 50,
		border = {
			style = "rounded",
		},
		buf_options = {
			modifiable = false,
			readonly = true,
			filetype = "markdown",
		},
		win_options = {
			wrap = true,
			linebreak = true,
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		},
	})

	preview_window.super.init(self, options)
end

function preview_window:mount()
	preview_window.super.mount(self)
end

return preview_window
