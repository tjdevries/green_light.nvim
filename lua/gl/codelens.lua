local api = vim.api

local M = {}

local namespaces = setmetatable({}, {
  __index = function(t, key)
    local value = api.nvim_create_namespace("greenlight_lsp_codelens:" .. key)
    rawset(t, key, value)
    return value
  end,
})

if not GREENLIGHT_OLD_DISPLAY then
  GREENLIGHT_OLD_DISPLAY = vim.lsp.codelens.display
end

M.display = function(lenses, bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.bo[bufnr].filetype ~= "go" then
    return GREENLIGHT_OLD_DISPLAY(lenses, bufnr, client_id)
  end

  if not lenses or not next(lenses) then
    return
  end

  local lenses_by_lnum = {}
  for _, lens in pairs(lenses) do
    local line_lenses = lenses_by_lnum[lens.range.start.line]
    if not line_lenses then
      line_lenses = {}
      lenses_by_lnum[lens.range.start.line] = line_lenses
    end
    table.insert(line_lenses, lens)
  end

  local ns = namespaces[client_id]
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local num_lines = api.nvim_buf_line_count(bufnr)
  for i = 0, num_lines do
    local line_lenses = lenses_by_lnum[i] or {}
    local chunks = { { "> ", "NonText" } }
    local num_line_lenses = #line_lenses
    for j, lens in ipairs(line_lenses) do
      local text = lens.command and lens.command.title or "Unresolved lens ..."
      table.insert(chunks, { text, "NonText" })
      if j < num_line_lenses then
        table.insert(chunks, { " | ", "LspCodeLensSeparator" })
      end
    end
    if #chunks > 1 then
      api.nvim_buf_set_extmark(bufnr, ns, i, 0, {
        hl_mode = "combine",
        virt_text = {},
        virt_lines = { chunks },
        virt_lines_above = true,
      })
    end
  end
end

M.telescope = function() end

return M
