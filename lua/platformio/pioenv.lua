local M = {}
local utils = require('platformio.utils')

M.default_env = "Default"
M.current_env = M.default_env

local function parse_ini_for_envs(filepath)
  local envs = {}
  local file = io.open(filepath, "r")
  if not file then
    return envs
  end
  for line in file:lines() do
    local match = line:match("%[env:(.-)%]")
    if match then
      table.insert(envs, match)
    end
  end
  file:close()
  return envs
end

local function cwd_pio_ini_path()
  return vim.uv.cwd() .. "/platformio.ini"
end

local function get_env_items()
  local items = { { text = M.default_env, env = M.default_env } }
  local envs = parse_ini_for_envs(cwd_pio_ini_path())
  for _, env in ipairs(envs) do
    table.insert(items, { text = env, env = env })
  end
  return items
end

-- Return environment flag for currently activated environment or empty string
-- if no env is activated (Default). For use in passing to pio commands.
function M.cmd_env_flag()
  if M.current_env ~= M.default_env then
    return "-e " .. M.current_env
  end
  return ""
end

function M.env_menu()
  local items = get_env_items()

  utils.select(items, {
    prompt = "Select PlatformIO Environment",
    format_item = function(item)
      local prefix = item.env == M.current_env and "● " or "  "
      return prefix .. item.text
    end,
  }, function(choice)
    if choice then
      M.current_env = choice.env
      vim.notify("Activated env: " .. choice.env, vim.log.levels.INFO)
    end
  end)
end

return M
