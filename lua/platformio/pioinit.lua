local M = {}

local utils = require('platformio.utils')
local boilerplate_gen = require('platformio.boilerplate').boilerplate_gen

local function pick_framework(board_details)
  local frameworks = board_details['frameworks'] or {}

  if #frameworks == 0 then
    vim.notify('No frameworks available for this board', vim.log.levels.WARN)
    return
  end

  if #frameworks == 1 then
    -- Only one framework, use it directly
    local selected_framework = frameworks[1]
    local command = 'pio project init --board ' .. board_details['id'] .. ' --project-option "framework=' .. selected_framework .. '"'
    utils.ToggleTerminal(command, 'right', function()
      vim.cmd(':PioLSP')
      boilerplate_gen(selected_framework)
    end)
    return
  end

  -- Multiple frameworks, show picker
  local items = {}
  for _, fw in ipairs(frameworks) do
    table.insert(items, { text = fw, framework = fw })
  end

  utils.select(items, {
    prompt = 'Select Framework',
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      local command = 'pio project init --board ' .. board_details['id'] .. ' --project-option "framework=' .. choice.framework .. '"'
      utils.ToggleTerminal(command, 'right', function()
        vim.cmd(':PioLSP')
        boilerplate_gen(choice.framework)
      end)
    end
  end)
end

local function pick_board(json_data)
  local items = {}
  for _, board in ipairs(json_data) do
    table.insert(items, {
      text = board.name,
      board = board,
      searchable = board.name .. ' ' .. (board.vendor or '') .. ' ' .. (board.platform or ''),
    })
  end

  utils.select(items, {
    prompt = 'Select Board',
    format_item = function(item)
      local vendor = item.board.vendor or ''
      local platform = item.board.platform or ''
      return string.format('%-35s │ %-20s │ %s', item.text, vendor, platform)
    end,
  }, function(choice)
    if choice then
      pick_framework(choice.board)
    end
  end)
end

function M.pioinit()
  if not utils.pio_install_check() then
    return
  end

  vim.notify('Loading boards...', vim.log.levels.INFO)

  -- Read stdout
  local command = 'pio boards --json-output'
  local handel = io.popen(command .. utils.devNul)
  if not handel then
    return
  end
  local json_str = handel:read('*a')
  handel:close()

  if #json_str == 0 then
    -- read stderr
    handel = io.popen(command .. ' 2>&1')
    if not handel then
      return
    end
    local command_output = handel:read('*a')
    handel:close()
    vim.notify('Error executing `' .. command .. '`: ' .. command_output, vim.log.levels.WARN)
    return
  end

  local json_data = vim.json.decode(json_str)
  pick_board(json_data)
end

return M
