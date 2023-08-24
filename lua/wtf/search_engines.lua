local M = {}

M.sources = {
  duck_duck_go = "https://duckduckgo.com/?q=",
  github = "https://github.com/search?type=issues&q=",
  google = "https://www.google.com/search?q=",
  stack_overflow = "https://stackoverflow.com/search?q=",
}

function M.get_completions()
  local list = {}
  for key, _ in pairs(M.sources) do
    table.insert(list, key)
  end
  return list
end

return M
