local get_diagnostics = require("wtf.get_diagnostics")
local get_filetype = require("wtf.get_filetype")
local gpt_request = require("wtf.gpt_request")
local display_response = require("wtf.display_response")

local function get_default_additional_instructions()
	return vim.g.wtf_default_additional_instructions or ""
end

local function get_language()
	return vim.g.wtf_language
end

local ai = function(additional_instructions)
	local diagnostics = get_diagnostics()
	local filetype = get_filetype()

	if diagnostics == nil then
		return print("No diagnostics found!")
	end

	local concatenatedDiagnostics = table.concat(diagnostics, "\n")

	local line = vim.fn.getline(".")

	local payload = "The coding language is "
		.. filetype
		.. ".\n This is a list of the errors: \n"
		.. concatenatedDiagnostics
		.. ". This is the line of code for context: \n"
		.. line

	if get_default_additional_instructions() ~= "" then
		payload = payload .. "\n" .. get_default_additional_instructions()
	end

	if additional_instructions then
		payload = payload .. "\n" .. additional_instructions
	end

	if get_language() ~= "" and get_language() ~= "english" then
		payload = payload .. "\nRespond only in " .. get_language()
	end

	print("Generating explanation...")

	local messages = {
		{
			role = "system",
			content = "You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. Give solutions as code snippets where applicable.",
		},
		{
			role = "user",
			content = payload,
		},
	}

	gpt_request(messages, display_response)
end

return ai
