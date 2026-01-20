local M = {}

local utils = require('platformio.utils')
local pioenv = require('platformio.pioenv')

function M.pioruncmd(target)
  utils.cd_pioini()
  local target_flag = ''
  if target ~= 'build' then
    target_flag = '--target ' .. target
  end
  local command = 'pio run ' .. target_flag .. ' ' .. pioenv.cmd_env_flag() .. utils.extra
  utils.ToggleTerminal(command, 'right')
end

function M.piorun(arg_table)
  if not utils.pio_install_check() then
    return
  end

  local arg = arg_table and arg_table[1] or ''

  if arg == '' or arg == nil then
    arg = 'upload'
  end

  M.pioruncmd(arg)
end

return M