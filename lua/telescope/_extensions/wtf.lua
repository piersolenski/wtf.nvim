local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

local Path = require("plenary.path")
local telescope_config = require("telescope.config").values
local wtf_config = require("wtf.config")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")

-- Retrieve the first line from each markdown file in the directory
-- Store the file paths for previewing
local function get_chat_summaries(dir)
  local file_paths = vim.fn.globpath(dir, "*.md", false, true)
  local lines = {}
  local files_with_first_line = {}
  for _, path in ipairs(file_paths) do
    local file = io.open(path, "r")
    if file then
      local first_line = file:read("*l")

      if first_line then
        -- Trim starting '# ' from the first line if present, in the case the
        -- text contains a markdown header
        first_line = first_line:match("^#%s*(.*)") or first_line

        table.insert(lines, first_line)
        table.insert(files_with_first_line, { first_line = first_line, path = path })
      end
      file:close()
    end
  end
  return files_with_first_line
end

local history = function(opts)
  opts = opts or {}

  local chat_dir = wtf_config.options.chat_dir
  local summaries = get_chat_summaries(chat_dir)

  local markdown_content = previewers.new_buffer_previewer({
    define_preview = function(self, entry)
      if not entry or not entry.path then
        return
      end
      local p = Path:new(entry.path)
      local content = p:readlines()
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
      vim.bo[self.state.bufnr].filetype = "markdown"
    end,
  })

  pickers
    .new(opts, {
      prompt_title = "WTF History",
      finder = finders.new_table({
        results = summaries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.first_line,
            ordinal = entry.first_line,
            path = entry.path,
          }
        end,
      }),
      sorter = telescope_config.generic_sorter(opts),
      previewer = markdown_content,
    })
    :find()
end

return telescope.register_extension({ exports = { history = history } })
