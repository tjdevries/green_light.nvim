local a = vim.api

local M = {}

_GreenLightBufnr = _GreenLightBufnr

M.get_bufnr = function()
  if not _GreenLightBufnr then
    _GreenLightBufnr = a.nvim_create_buf(false, false)
    a.nvim_buf_set_name(_GreenLightBufnr, "green_light")
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

  M.hide(bufnr)
  vim.cmd('40 vsplit ' .. vim.fn.expand(string.format("#%s", bufnr)))
end

-- M.reset()
M.vsplit()

return M
