local M = {}

local config = require('platformio').config

-- Backend selection for UI components
local function get_config()
  local ok, platformio = pcall(require, 'platformio')
  return ok and platformio.config or {}
end

local function resolve_backend(type)
  local cfg = get_config()
  local preference = type == 'picker' and cfg.picker or cfg.terminal

  if preference == 'auto' or not preference then
    -- Auto-detect available backends
    if type == 'picker' then
      if pcall(require, 'snacks') then
        return 'snacks'
      elseif pcall(require, 'telescope') then
        return 'telescope'
      else
        error('platformio.nvim requires either snacks.nvim or telescope.nvim for picker functionality')
      end
    else -- terminal
      if pcall(require, 'snacks') then
        return 'snacks'
      elseif pcall(require, 'toggleterm') then
        return 'toggleterm'
      else
        error('platformio.nvim requires either snacks.nvim or toggleterm.nvim for terminal functionality')
      end
    end
  end

  return preference
end

-- Picker implementation
function M.select(items, opts, callback)
  local backend = resolve_backend('picker')

  if backend == 'snacks' then
    Snacks.picker.select(items, opts, callback)
  elseif backend == 'telescope' then
    vim.ui.select(items, {
      prompt = opts.prompt,
      format_item = opts.format_item,
    }, callback)
  end
end

-- Terminal implementation
function M.terminal(command, opts)
  local backend = resolve_backend('terminal')

  if backend == 'snacks' then
    return Snacks.terminal(command, opts)
  elseif backend == 'toggleterm' then
    local Terminal = require('toggleterm.terminal').Terminal
    local position_map = {
      right = 'vertical',
      left = 'vertical',
      top = 'horizontal',
      bottom = 'horizontal',
      float = 'float',
    }
    local direction = opts.win and position_map[opts.win.position] or 'float'

    local term = Terminal:new({
      cmd = command,
      direction = direction,
      hidden = true,
      on_exit = opts.on_exit,
      on_close = opts.on_exit,
    })
    term:toggle()

    return {
      buf = term.bufnr,
      buf_valid = function(self)
        return self.buf and vim.api.nvim_buf_is_valid(self.buf)
      end,
      show = function()
        term:toggle()
      end,
      hide = function()
        term:close()
      end,
    }
  end
end

-- Shell-specific command separator
local shell = vim.o.shell
local is_nushell = shell:find('nu')
local sep = is_nushell and '; ' or ' && '

M.extra = sep .. 'echo .' .. sep .. 'echo .' .. sep .. 'echo Please Press ENTER to continue'

-- Terminal tracking
M.terminals = {
  cli = nil,
  mon = nil,
}

function M.strsplit(inputstr, del)
  local t = {}
  if type(inputstr) == 'string' and inputstr and inputstr ~= '' then
    for str in string.gmatch(inputstr, '([^' .. del .. ']+)') do
      table.insert(t, str)
    end
  end
  return t
end

function M.check_prefix(str, prefix)
  return str:sub(1, #prefix) == prefix
end

local function pathmul(n)
  return '..' .. string.rep('/..', n)
end

------------------------------------------------------
local is_windows = jit.os == 'Windows'

M.devNul = is_windows and ' 2>./nul' or ' 2>/dev/null'

function M.enter()
  local shell = vim.o.shell
  if is_windows then
    return vim.fn.executable('pwsh') and '\r' or '\r\n'
  elseif shell:find('nu') then
    return '\r'
  else
    return '\n'
  end
end

------------------------------------------------------
-- INFO: SnacksTerminal - replacement for ToggleTerminal
function M.ToggleTerminal(command, direction, exit_callback)
  if type(exit_callback) ~= 'function' then
    exit_callback = function() end
  end

  local is_monitor = string.find(command or '', ' monitor')
  local term_key = is_monitor and 'mon' or 'cli'

  -- Check if terminal already exists and is valid
  local existing = M.terminals[term_key]
  if existing and existing:buf_valid() then
    -- Terminal exists, show it and send command
    existing:show()
    if command and command ~= '' then
      vim.defer_fn(function()
        if existing.buf and vim.api.nvim_buf_is_valid(existing.buf) then
          local chan = vim.bo[existing.buf].channel
          if chan and chan > 0 then
            vim.api.nvim_chan_send(chan, command .. M.enter())
          end
        end
      end, 50)
    end
    return
  end

  -- Determine position based on direction
  -- Supports: 'float', 'horizontal' (bottom), 'right', 'left', 'top'
  local position = direction
  if direction == 'horizontal' then
    position = 'bottom'
  elseif not direction or direction == 'vertical' then
    position = 'float'
  end

  local title = is_monitor
    and 'Pio Monitor: [Esc then q to hide, Ctrl-c to force hide]'
    or 'Pio CLI: [Esc then q to hide, Ctrl-c to force hide]'

  -- Create new terminal
  local term = M.terminal(command, {
    win = {
      position = position,
      title = title,
      height = position == 'float' and 0.85 or 0.3,
      width = position == 'float' and 0.85 or nil,
      border = 'rounded',
      wo = {
        winbar = '',
      },
    },
    on_exit = function()
      M.terminals[term_key] = nil
      exit_callback()
    end,
  })

  -- Store terminal reference
  M.terminals[term_key] = term

  -- Set up keymaps immediately and with defer
  local function setup_terminal_buffer()
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
      -- Set up keymaps that work in multiple modes (use pcall to avoid errors)
      -- Escape to normal mode from terminal mode - this is critical for getting unstuck
      pcall(vim.keymap.set, 't', '<Esc>', [[<C-\><C-n>]], { buffer = term.buf, silent = true })
      -- Alternative escape with double Esc
      pcall(vim.keymap.set, 't', '<Esc><Esc>', [[<C-\><C-n>]], { buffer = term.buf, silent = true })

      -- Hide terminal with 'q' in normal mode
      pcall(vim.keymap.set, 'n', 'q', function()
        term:hide()
      end, { buffer = term.buf, desc = 'Hide terminal', silent = true })

      -- Force close with Ctrl-C in normal mode (fallback)
      pcall(vim.keymap.set, 'n', '<C-c>', function()
        term:hide()
      end, { buffer = term.buf, desc = 'Force hide terminal', silent = true })

      -- Also allow <C-\><C-n> as explicit escape (standard Neovim terminal escape)
      pcall(vim.keymap.set, 't', '<C-\\><C-n>', '<C-\\><C-n>', { buffer = term.buf, silent = true })
    end
  end

  -- Try to set up immediately
  setup_terminal_buffer()

  -- And also defer in case the buffer isn't ready yet
  vim.defer_fn(setup_terminal_buffer, 50)
  vim.defer_fn(setup_terminal_buffer, 150)
end

------------------------------------------------------
-- Get all pio terminals for listing
function M.get_pio_terminals()
  local terms = {}
  for name, term in pairs(M.terminals) do
    if term and term:buf_valid() then
      table.insert(terms, {
        name = name == 'cli' and 'PIO CLI' or 'PIO Monitor',
        term = term,
        key = name,
      })
    end
  end
  return terms
end

----------------------------------------------------------------------------------------

local paths = { '.', '..', pathmul(1), pathmul(2), pathmul(3), pathmul(4), pathmul(5) }

function M.file_exists(name)
  local f = io.open(name, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function M.get_pioini_path()
  for _, path in pairs(paths) do
    if M.file_exists(path .. '/platformio.ini') then
      return path
    end
  end
end

function M.cd_pioini()
  if vim.g.platformioRootDir ~= nil then
    vim.cmd('cd ' .. vim.g.platformioRootDir)
  else
    vim.cmd('cd ' .. M.get_pioini_path())
  end
end

function M.pio_install_check()
  local handel = is_windows and assert(io.popen('where.exe pio 2>./nul')) or assert(io.popen('which pio 2>/dev/null'))
  local pio_path = assert(handel:read('*a'))
  handel:close()

  if #pio_path == 0 then
    vim.notify('Platformio not found in the path', vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.async_shell_cmd(cmd, callback)
  local output = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = false,

    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(output, line)
          end
        end
      end
    end,

    on_exit = function(_, code)
      callback(output, code)
    end,
  })
end

function M.shell_cmd_blocking(command)
  local handle = io.popen(command, 'r')
  if not handle then
    return nil, 'failed to run command'
  end

  local result = handle:read('*a')
  handle:close()

  return result
end

return M
