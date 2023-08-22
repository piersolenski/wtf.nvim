local function get_model_id()
	local model = vim.g.wtf_openai_model_id
	if model == nil then
		if vim.g.wtf_model_id_complained == nil then
			local message =
				"No model id specified. Please set openai_model_id in the setup table. Defaulting to gpt-3.5-turbo for now"
			vim.fn.confirm(message, "&OK", 1, "Warning")
			vim.g.wtf_model_id_complained = 1
		end
		return "gpt-3.5-turbo"
	end
	return model
end

local function get_api_key()
	local api_key = vim.g.wtf_openai_api_key
	if api_key == nil then
		local key = os.getenv("OPENAI_API_KEY")
		if key ~= nil then
			return key
		end
		local message =
			"No API key found. Please set openai_api_key in the setup table or set the $OPENAI_API_KEY environment variable."
		vim.fn.confirm(message, "&OK", 1, "Warning")
		return nil
	end
	return api_key
end

local function gpt_request(messages, callback, callbackTable)
	local api_key = get_api_key()
	if api_key == nil then
		return nil
	end

	-- Check if curl is installed
	if vim.fn.executable("curl") == 0 then
		vim.fn.confirm("curl installation not found. Please install curl to use Wtf", "&OK", 1, "Warning")
		return nil
	end

	local curlRequest

	-- Create temp file
	local tempFilePath = vim.fn.tempname()
	local tempFile = io.open(tempFilePath, "w")
	if tempFile == nil then
		print("Error creating temp file")
		return nil
	end

	-- Write dataJSON to temp file
	local dataJSON = vim.json.encode({
		model = get_model_id(),
		messages = messages,
	})
	tempFile:write(dataJSON)
	tempFile:close()

	-- Escape the name of the temp file for command line
	local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)

	-- Check if the user is on windows
	local isWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

	if isWindows ~= true then
		-- Linux
		curlRequest = string.format(
			'curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer '
				.. api_key
				.. '" --data-binary "@'
				.. tempFilePathEscaped
				.. '"; rm '
				.. tempFilePathEscaped
				.. " > /dev/null 2>&1"
		)
	else
		-- Windows
		curlRequest = string.format(
			'curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer '
				.. api_key
				.. '" --data-binary "@'
				.. tempFilePathEscaped
				.. '" & del '
				.. tempFilePathEscaped
				.. " > nul 2>&1"
		)
	end

	vim.fn.jobstart(curlRequest, {
		stdout_buffered = true,
		on_stdout = function(_, data, _)
			local response = table.concat(data, "\n")
			local success, responseTable = pcall(vim.json.decode, response)

			if success == false or responseTable == nil then
				if response == nil then
					response = "nil"
				end
				print("Bad or no response: " .. response)
				return nil
			end

			if responseTable.error ~= nil then
				print("OpenAI Error: " .. responseTable.error.message)
				return nil
			end

			callback(responseTable, callbackTable)
		end,
		on_stderr = function(_, data, _)
			return data
		end,
		on_exit = function(_, data, _)
			return data
		end,
	})
end

return gpt_request
