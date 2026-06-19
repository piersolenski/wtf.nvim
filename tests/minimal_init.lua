local function clone_repo(repo_url, dest_dir)
  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.system({ "git", "clone", repo_url, dest_dir })
  end
end

local nui_dir = os.getenv("NUI_DIR") or "/tmp/nui.nvim"

local nui_repo = "https://github.com/MunifTanjim/nui.nvim"

clone_repo(nui_repo, nui_dir)

vim.opt.swapfile = false

vim.opt.rtp:append(".")
vim.opt.rtp:append(nui_dir)

package.path = package.path .. ";" .. nui_dir .. "/lua/?.lua;" .. nui_dir .. "/lua/?/init.lua"

vim.cmd.runtime({ "plugin/nui.vim" })

-- Load luassert as the global assertion library
_G.assert = require("luassert")

-- Minimal test runner state
local suites = {}
local current_suite = nil
local ancestor_stack = {}

local function full_suite_name(suite)
  local names = {}
  local node = suite
  while node do
    table.insert(names, 1, node.name)
    node = node.parent
  end
  return table.concat(names, " ")
end

_G.describe = function(name, fn)
  local suite = {
    name = name,
    parent = current_suite,
    before = {},
    after = {},
    tests = {},
  }

  if current_suite then
    current_suite.children = current_suite.children or {}
    table.insert(current_suite.children, suite)
  else
    table.insert(suites, suite)
  end

  current_suite = suite
  table.insert(ancestor_stack, suite)

  local ok, err = pcall(fn)

  table.remove(ancestor_stack)
  current_suite = suite.parent

  if not ok then
    error(string.format("Error in describe('%s'): %s", name, err))
  end
end

_G.it = function(name, fn)
  if not current_suite then
    error("it() called outside of describe()")
  end

  local before = {}
  local after = {}

  for _, suite in ipairs(ancestor_stack) do
    for _, b in ipairs(suite.before) do
      table.insert(before, b)
    end
    for _, a in ipairs(suite.after) do
      table.insert(after, a)
    end
  end

  table.insert(current_suite.tests, {
    name = name,
    fn = fn,
    before = before,
    after = after,
  })
end

_G.before_each = function(fn)
  if not current_suite then
    error("before_each() called outside of describe()")
  end
  table.insert(current_suite.before, fn)
end

_G.after_each = function(fn)
  if not current_suite then
    error("after_each() called outside of describe()")
  end
  table.insert(current_suite.after, fn)
end

_G.pending = function(reason)
  error({ __pending = true, reason = reason or "" })
end

local function run_test(suite, test)
  -- Create a fresh modifiable buffer for each test so that popup windows or
  -- other side effects from previous tests do not leak into the current test.
  local original_win = vim.api.nvim_get_current_win()
  local test_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(test_buf)

  for _, before in ipairs(test.before) do
    before()
  end

  local ok, err
  if test.fn then
    local arity = debug.getinfo(test.fn).nparams
    if arity > 0 then
      local done_called = false
      local done_fn = function()
        done_called = true
      end

      ok, err = pcall(test.fn, done_fn)

      if ok and not done_called then
        local wait_ok = vim.wait(5000, function()
          return done_called
        end, 100)
        if not wait_ok then
          ok = false
          err = "Async test timed out waiting for done()"
        end
      end

      -- Allow any pending vim.defer_fn callbacks from this test to complete
      -- before moving on to the next test.
      if ok then
        vim.wait(150, function()
          return false
        end)
      end
    else
      ok, err = pcall(test.fn)
    end
  end

  for _, after in ipairs(test.after) do
    local after_ok, after_err = pcall(after)
    if ok and not after_ok then
      ok = false
      err = after_err
    end
  end

  -- Restore the original buffer/window and delete the test buffer
  if vim.api.nvim_win_is_valid(original_win) then
    vim.api.nvim_set_current_win(original_win)
  end
  if vim.api.nvim_buf_is_valid(test_buf) then
    vim.api.nvim_buf_delete(test_buf, { force = true })
  end

  return ok, err
end

function RunWtfTests(dir)
  local spec_files = vim.fn.globpath(dir, "**/*_spec.lua", false, true)
  table.sort(spec_files)

  for _, file in ipairs(spec_files) do
    local ok, err = pcall(dofile, file)
    if not ok then
      print(string.format("Error loading %s: %s", file, err))
    end
  end

  local total = 0
  local passed = 0
  local failed = 0
  local pending_count = 0
  local failure_details = {}

  local function run_suite(suite)
    for _, test in ipairs(suite.tests) do
      total = total + 1
      local ok, err = run_test(suite, test)
      local label = full_suite_name(suite) .. " " .. test.name

      if not ok and type(err) == "table" and err.__pending then
        pending_count = pending_count + 1
        print("Pending || " .. label .. " " .. err.reason)
      elseif ok then
        passed = passed + 1
        print("Success || " .. label)
      else
        failed = failed + 1
        print("Fail    || " .. label)
        print(tostring(err))
        table.insert(failure_details, { label = label, err = err })
      end
    end

    if suite.children then
      for _, child in ipairs(suite.children) do
        run_suite(child)
      end
    end
  end

  for _, suite in ipairs(suites) do
    run_suite(suite)
  end

  print("")
  print(string.format("Success: %d", passed))
  print(string.format("Failed : %d", failed))
  print(string.format("Pending: %d", pending_count))
  print(string.format("Total  : %d", total))

  if failed > 0 then
    vim.cmd("1cq")
  else
    vim.cmd("0cq")
  end
end
