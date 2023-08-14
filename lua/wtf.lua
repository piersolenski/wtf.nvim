local wtf = {}

local function with_defaults(options)
	return {
		search_engine = options.search_engine or "Google",
	}
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function wtf.setup(options)
	-- avoid setting global values outside of this function. Global state
	-- mutations are hard to debug and test, so having them in a single
	-- function/module makes it easier to reason about all possible changes
	wtf.options = with_defaults(options)
end

function wtf.is_configured()
	return wtf.options ~= nil
end


local function get_diagnostic()
	local line = vim.fn.line(".") - 1
	local bufnr = vim.api.nvim_win_get_buf(0) -- 0 = current buffer
	local diags = vim.diagnostic.get(bufnr, { lnum = line, severity = { min = vim.diagnostic.severity.HINT } })

	if #diags == 0 then
		return print("No diagnostics found")
	end

	local diag = diags[1]
	local lines = vim.split(diag.message, "\n")
	local message = lines[1]
	local filetype = vim.bo.filetype

  return { message = message, filetype = filetype }
end

function wtf.ai()
  local diagnostic = get_diagnostic()
  if diagnostic then
    print("Generating explanation...")
    vim.cmd.Chat("question Explain this " .. diagnostic.filetype .. " error:" .. diagnostic.message)
  end
end


function wtf.search()
  local diagnostic = get_diagnostic()
  if diagnostic then
    local search_string = diagnostic.filetype .. ' ' .. diagnostic.message
    local google_search_url = "https://www.google.com/search?q=" .. vim.fn.escape(search_string, ' ')

    local opener_command
    if vim.fn.has("win32") == 1 then
        opener_command = "start"
    elseif vim.fn.has("macunix") == 1 then
        opener_command = "open"
    else
        opener_command = "xdg-open"
    end

    local command = opener_command .. " " .. "'" .. google_search_url .. "'"
    print(command)

    -- Open the URL using the appropriate command
    vim.fn.system(command)
  end
end

wtf.options = nil
return wtf
