local M = {}

M.sources = {
  google = "https://www.google.com/search?q=",
  duck_duck_go = "https://duckduckgo.com/?q=",
  stack_overflow = "https://stackoverflow.com/search?q=",
  github = "https://github.com/search?type=issues&q=",
}

function M.get_completions()
  local list = {}
  for key, _ in pairs({
    google = "https://www.google.com/search?q=",
    duck_duck_go = "https://duckduckgo.com/?q=",
    stack_overflow = "https://stackoverflow.com/search?q=",
    github = "https://github.com/search?type=issues&q=",
  }) do
    table.insert(list, key)
  end
  return list
end

return M
