local M = {}

local curl = require('plenary.curl')
local utils = require('platformio.utils')

local function pick_library(json_data)
  local items = {}
  for _, lib in ipairs(json_data['items'] or {}) do
    table.insert(items, {
      text = lib.name,
      name = lib.name,
      owner = lib.owner.username,
      description = lib.description or '',
    })
  end

  if #items == 0 then
    vim.notify('No libraries found', vim.log.levels.WARN)
    return
  end

  utils.select(items, {
    prompt = 'Select Library',
    format_item = function(item)
      return string.format('%-20s │ %-20s │ %s', item.name, item.owner, item.description:sub(1, 50))
    end,
  }, function(choice)
    if choice then
      local pkg_name = choice.owner .. '/' .. choice.name
      local command = 'pio pkg install --library "' .. pkg_name .. '"'
      utils.ToggleTerminal(command, 'vertical', function()
        vim.cmd(':PioLSP')
      end)
    end
  end)
end

function M.piolib(lib_arg_list)
  if not utils.pio_install_check() then
    return
  end

  local lib_str = ''
  for _, v in pairs(lib_arg_list) do
    lib_str = lib_str .. v .. '+'
  end

  vim.notify('Searching libraries...', vim.log.levels.INFO)

  local url = 'https://api.registry.platformio.org/v3/search'
  local res = curl.get(url, {
    insecure = true,
    timeout = 20000,
    headers = { content_type = 'application/json' },
    query = {
      query = lib_str,
      limit = 30,
      sort = 'popularity',
    },
  })

  if res['status'] == 200 then
    local json_data = vim.json.decode(res['body'])
    pick_library(json_data)
  else
    vim.notify(
      'API Request to platformio returned HTTP code: ' .. res['status'] .. '\nplease run `curl -LI ' .. url .. '` for complete information',
      vim.log.levels.ERROR
    )
  end
end

return M
