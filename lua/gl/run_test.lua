local a = vim.api

---@brief [[
--- Uses colors:
---
---     - GoTestSuccess: Used to highlight succesful tests
---     - GoTestFail   : Used to highlight failed tests
---@brief ]]

local Job = require('plenary.job')
-- local log = require('plenary.log')

local gl_win = require('gl.window')

local ns_gotest = a.nvim_create_namespace('gotest')

local test_run = "~ Go Test ~"
TestRuns = {
  [test_run] = {
    output = {}
  }
}

TestOrdered = { test_run }

local TestCase = {}
TestCase.__index = TestCase

function TestCase:new(name, decoded)
  return setmetatable({
    name = name,
    decoded = decoded,
    result = "pending",
    output = {},

    extmark_start = TestCase:_get_id(name .. "_start"),
    extmark_final = TestCase:_get_id(name .. "_final")
  }, self)
end

local test_case_ids, test_case_count = {}, 0
function TestCase:_get_id(id)
  if not test_case_ids[id] then
    test_case_count = test_case_count + 1
    test_case_ids[id] = test_case_count
  end

  return test_case_ids[id]
end

function TestCase:add_header(bufnr)
  local line = "===== " .. self.name .. " ====="

  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line, "" })
  a.nvim_buf_set_extmark(bufnr, ns_gotest, vim.api.nvim_buf_line_count(bufnr) - 2, 0, { id = self.extmark_start })
  a.nvim_buf_set_extmark(bufnr, ns_gotest, vim.api.nvim_buf_line_count(bufnr) - 1, 0, { id = self.extmark_final })
end

local get_extmark_row = function(bufnr, extmark_id)
  local extmark_locations = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_gotest, extmark_id, {})
  return extmark_locations[1]
end

function TestCase:get_start_row(bufnr)
  local extmark_id = self.extmark_start
  return get_extmark_row(bufnr, extmark_id)
end

function TestCase:get_final_row(bufnr)
  local extmark_id = self.extmark_final
  return get_extmark_row(bufnr, extmark_id)
end

function TestCase:save_output(output)
  for _, value in ipairs(vim.split(vim.trim(output), "\n")) do
    table.insert(self.output, value)
  end
end

function TestCase:show_output(bufnr)
  self.displayed = true

  local start_row = self:get_start_row(bufnr)
  local final_row = self:get_final_row(bufnr)
  if not start_row or not final_row then return print("Couldnt find for: ", self.name) end

  a.nvim_buf_set_lines(bufnr, start_row + 1, final_row, false, self.output)
end

function TestCase:hide_output(bufnr)
  self.displayed = false

  local start_row = self:get_start_row(bufnr)
  local final_row = self:get_final_row(bufnr)
  if not start_row or not final_row then
    return print("Couldnt find for: ", self.name)
  end

  a.nvim_buf_set_lines(bufnr, start_row + 1, final_row, false, {})
end

function TestCase:toggle_output(bufnr)
  if self.displayed then
    self:hide_output(bufnr)
  else
    self:show_output(bufnr)
  end
end

function TestCase:set_result(bufnr, result)
  self.result = result

  local highlight_name = 'Error'
  if result == 'pass' then
    highlight_name = 'GoTestSuccess'
  elseif result == 'fail' then
    highlight_name = 'GoTestFail'
  end

  a.nvim_buf_add_highlight(bufnr, ns_gotest, highlight_name, self:get_start_row(bufnr), 0, -1)
end

-- {{{
function TestCase:is_pass() return self.result == 'pass' end
function TestCase:is_fail() return self.result == 'fail' end
function TestCase:is_pend() return self.result == 'pending' end
-- }}}

local TestRun = {}
TestRun.__index = TestRun

function TestRun:new(opts)
  return setmetatable({
    test_pattern = opts.test_pattern,
    file_pattern = opts.file_pattern or './...',
    cwd = opts.cwd or vim.loop.cwd(),
  }, self)
end

function TestRun:run()
  TestRun._current_run = self
  TestRun._current_bufnr = gl_win.get_bufnr()

  local bufnr = TestRun._current_bufnr

  self:set_keymaps(bufnr)

  a.nvim_buf_clear_namespace(0, ns_gotest, 0, -1)
  a.nvim_buf_clear_namespace(bufnr, ns_gotest, 0, -1)

  a.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  self.cases = {}
  self.ordered = {}

  local args = { 'test', '-json' }
  if self.test_pattern then
    table.insert(args, '-run')
    table.insert(args, self.test_pattern)
  end
  table.insert(args, self.file_pattern)

  local j = Job:new {
    command = 'go',
    args = args,
    cwd = self.cwd,

    on_stdout = vim.schedule_wrap(function(_, line)
      local decoded = vim.fn.json_decode(line)
      self:handle_line(bufnr, decoded)
    end),

    on_exit = vim.schedule_wrap(function()
      for _, test_case in pairs(self.cases) do
        if test_case:is_pass() then
          test_case:hide_output(bufnr)
        end
      end
      if true then return end

      -- put all the things in a window
      -- local results = self:result()

      for _, name in pairs(TestOrdered) do
        local test = TestRuns[name]

        local contents = {}
        for _, val in ipairs(vim.split(vim.inspect(test), "\n")) do
          table.insert(contents, val)
        end

        -- add_header_content(bufnr, name, contents)
      end
    end),
  }

  j:start()
end

function TestRun:add_case(bufnr, test_name, decoded)
  table.insert(self.ordered, decoded.Test)

  self.cases[test_name] = TestCase:new(test_name, decoded)
  self.cases[test_name]:add_header(bufnr)

  return self.cases[test_name]
end

function TestRun:handle_line(bufnr, decoded)
  local action = decoded.Action
  local test_name = decoded.Test or test_run

  if action == "run" then
    return self:add_case(bufnr, test_name, decoded)
  end

  local test_case = self.cases[test_name]
  if not test_case then
    test_case = self:add_case(bufnr, test_name, decoded)
  end

  if action == "output" then
    test_case:save_output(decoded.Output)
  elseif action == "fail" or action == "pass" then
    test_case:set_result(bufnr, action)

    if test_case:is_fail() then
      test_case:show_output(bufnr)
    end
  else
    print("Missing this one", vim.inspect(decoded))
  end
end

function TestRun:find_test_case(line)
  local row = line - 1

  while row > 0 do
    for _, test_case in pairs(self.cases) do
      if test_case:get_start_row() == row then
        return test_case
      end
    end

    row = row - 1
  end

  return
end

function TestRun:set_keymaps(bufnr)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', ':lua require("gl.run_test").toggle_display()<CR>', { noremap = true, silent = true })
end

function TestRun.toggle_display()
  local run = assert(TestRun._current_run, "Must have an existing run")

  local test_case = run:find_test_case(vim.api.nvim_win_get_cursor(0)[1])
  test_case:toggle_output(TestRun._current_bufnr)

  if not test_case.displayed then
    vim.api.nvim_win_set_cursor(0, { test_case:get_start_row() + 1, 0 })
  end
end

return {
  TestCase = TestCase,
  TestRun = TestRun,

  toggle_display = TestRun.toggle_display
}
