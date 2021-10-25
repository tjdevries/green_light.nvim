local a = vim.api

local M = {}

_GreenLightBufnr = _GreenLightBufnr

M.get_bufnr = function()
  if not _GreenLightBufnr or not vim.api.nvim_buf_is_valid(_GreenLightBufnr) then
    _GreenLightBufnr = a.nvim_create_buf(false, true)
    a.nvim_buf_set_name(_GreenLightBufnr, "green_light")
    a.nvim_buf_set_option(_GreenLightBufnr, "tabstop", 8)
  end

  return _GreenLightBufnr
end

M.reset = function()
  _GreenLightBufnr = nil
end

M.hide = function(bufnr)
  for _, win in ipairs(a.nvim_list_wins()) do
    if a.nvim_win_get_buf(win) == bufnr then
      a.nvim_win_close(win, true)
    end
  end
end

M.vsplit = function()
  local bufnr = M.get_bufnr()

  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win_id) == bufnr then
      return
    end
  end

  M.hide(bufnr)
  vim.cmd("80 vsplit " .. vim.fn.expand(string.format("#%s", bufnr)))
  vim.api.nvim_win_set_option(0, "winfixwidth", true)
end

M.float = function()
  local bufnr = M.get_bufnr()
  M.hide(bufnr)

  require("plenary.window.float").percentage_range_window(0.5, 0.5, {
    bufnr = bufnr,
  })
end

return M
