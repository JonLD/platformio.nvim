-- Vim nargs options
-- 0: No arguments.
-- 1: Exactly one argument.
-- ?: Zero or one argument.
-- *: Any number of arguments (including none).
-- +: At least one argument.
-- -1: Zero or one argument (like ?, explicitly).

local utils = require('platformio.utils')
local piolsserial = require('platformio.piolsserial')

-- Pioinit
vim.api.nvim_create_user_command('Pioinit', function()
  require('platformio.pioinit').pioinit()
end, { force = true })

-- Piolsp
vim.api.nvim_create_user_command('PioLSP', function()
  vim.schedule(function()
    require('platformio.piolsp').piolsp()
  end)
end, {})

-- Pioenv (select environment)
vim.api.nvim_create_user_command('Pioenv', function()
  require('platformio.pioenv').env_menu()
end, {})

-- Piorun
vim.api.nvim_create_user_command('Piorun', function(opts)
  local args = opts.args
  require('platformio.piorun').piorun({ args })
end, {
  nargs = '?',
  complete = function(_, _, _)
    return { 'upload', 'uploadfs', 'build', 'clean' } -- Autocompletion options
  end,
})

-- Piomon
piolsserial.sync_ttylist()
vim.api.nvim_create_user_command('Piomon', function(opts)
  local args = opts.fargs
  require('platformio.piomon').piomon(args)
end, {
  nargs = '*',

  complete = function(_, cmd_line)
    local parts = vim.split(cmd_line, '%s+')
    local BAUD = { '4800', '9600', '57600', '115200' }
    local ports = {}
    for _, item in ipairs(piolsserial.tty_list) do
      table.insert(ports, item.port)
    end
    if #parts == 2 then
      return BAUD
    end
    if #parts == 3 then
      return ports
    end
    return {}
  end,
})

-- Piolsserial
vim.api.nvim_create_user_command('Piolsserial', function()
  require('platformio.piolsserial').print_tty_list()
end, {})

-- Piolib
vim.api.nvim_create_user_command('Piolib', function(opts)
  local args = vim.split(opts.args, ' ')
  require('platformio.piolib').piolib(args)
end, {
  nargs = '+',
})

-- Piocmd    Uses configured terminal_position
vim.api.nvim_create_user_command('Piocmd', function(opts)
  local cmd_table = vim.split(opts.args, ' ')
  require('platformio.piocmd').piocmd(cmd_table)
end, {
  nargs = '*',
})

-- Piocmdv    Piocmd vertical (right) terminal
vim.api.nvim_create_user_command('Piocmdv', function(opts)
  local cmd_table = vim.split(opts.args, ' ')
  require('platformio.piocmd').piocmd(cmd_table, 'right')
end, {
  nargs = '*',
})

-- Piocmdh    Piocmd horizontal terminal
vim.api.nvim_create_user_command('Piocmdh', function(opts)
  local cmd_table = vim.split(opts.args, ' ')
  require('platformio.piocmd').piocmd(cmd_table, 'horizontal')
end, {
  nargs = '*',
})

-- Piocmdf    Piocmd float terminal
vim.api.nvim_create_user_command('Piocmdf', function(opts)
  local cmd_table = vim.split(opts.args, ' ')
  require('platformio.piocmd').piocmd(cmd_table, 'float')
end, {
  nargs = '*',
})

-- Piodebug
vim.api.nvim_create_user_command('Piodebug', function()
  require('platformio.piodebug').piodebug()
end, {})

------------------------------------------------------

-- INFO: List PIO Terminals
vim.api.nvim_create_user_command('PioTermList', function()
  local terminals = utils.get_pio_terminals()

  if #terminals == 0 then
    vim.notify('No PIO terminal windows found.', vim.log.levels.INFO)
    return
  end

  utils.select(terminals, {
    prompt = 'Select PIO Terminal',
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      choice.term:show()
      vim.notify('Switched to: ' .. choice.name, vim.log.levels.INFO)
    end
  end)
end, {})
