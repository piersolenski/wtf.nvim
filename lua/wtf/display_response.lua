local preview_window = require("wtf.preview_window")

local function split_string_by_line(text)
	local lines = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		table.insert(lines, line)
	end
	return lines
end

local function display_response(responseTable)
	if responseTable == nil then
		return nil
	end
	local message = responseTable.choices[1].message.content
	message = split_string_by_line(message)

	local event = require("nui.utils.autocmd").event

	local popup = preview_window()

	vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, message)

	popup:mount()

	-- unmount component when cursor leaves buffer
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)
end

return display_response
