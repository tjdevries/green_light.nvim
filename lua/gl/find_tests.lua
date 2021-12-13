local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}

-- TODO: This doesn't handle `T.Run()` style tests, we will have to do that part later
local TestQuery = [[
(
 (function_declaration
   name: (identifier) @test_name
   parameters: (parameter_list
       (parameter_declaration
                name: (identifier)
                type: (pointer_type
                    (qualified_type
                     package: (package_identifier) @_param_package
                     name: (type_identifier) @_param_name))))
    ) @testfunc

 (#contains? @test_name "Test")
 (#match? @_param_package "testing")
 (#match? @_param_name "T")
)
]]

M.list_tests = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local query = vim.treesitter.parse_query("go", TestQuery)

  local test_names = {}
  for id, node, metadata in query:iter_captures(tree:root(), bufnr, 0, -1) do
    local name = query.captures[id] -- name of the capture in the query
    if name == "test_name" then
      table.insert(test_names, vim.treesitter.get_node_text(node, bufnr))
    end
  end

  local title = "Possible Tests"
  pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table {
      results = test_names,
      entry_maker = function(entry)
        return {
          value = entry,
          text = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    },
    previewer = false,
    sorter = conf.generic_sorter {},
    attach_mappings = function(_)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.schedule(function()
          vim.lsp.buf.execute_command {
            command = "gopls.run_tests",
            arguments = { { URI = vim.uri_from_bufnr(0), Tests = { selection.value } } },
          }
        end)

        actions.close(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return M
