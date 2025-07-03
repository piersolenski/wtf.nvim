local function create_summary(string, summary_length)
  local summary

  -- Removes new lines
  summary = string:gsub("\n", "")
  -- Remove leading hash
  summary = summary:match("^#%s*(.*)") or string

  if #summary > summary_length then
    summary = summary:sub(1, summary_length) .. "…" -- Truncates and adds ellipsis
  end

  return summary
end

return create_summary
