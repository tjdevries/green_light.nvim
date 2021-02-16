local Job = require('plenary.job')

local M = {}

M.get = function(cwd)
  return vim.fn.json_decode(table.concat(Job:new {
    command = 'go',
    args = {'list', '-m', '-json'},
    cwd = cwd or vim.loop.cwd(),
  }:sync(), ""))
end

M.find_path = function(module_info, package)
  local module_path = module_info.Path
  local module_dir = module_info.Dir

  local _, finish = string.find(package, module_path, 1, 30)
  return module_dir .. string.sub(package, finish + 1)
end

return M
