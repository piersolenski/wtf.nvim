local function to_title_case(input)
  local output = input:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
  return output
end

return to_title_case
