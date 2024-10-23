local M = {}

local Menu = require("nui.menu")

M.default_env = "Default"

M.current_env = M.default_env

local function parse_ini_for_envs(filepath)
	local envs = {}
	for line in io.lines(filepath) do
		local match = line:match(".*%[env%:(.*)%].*")
		if match ~= nil then
			table.insert(envs, match)
		end
	end
	return envs
end

local function cwd_pio_ini_path()
	return vim.uv.cwd() .. "/platformio.ini"
end

local function env_menu_items()
	local env_menu = { Menu.item(M.default_env) }
	local envs = parse_ini_for_envs(cwd_pio_ini_path())
	for _, env in pairs(envs) do
		print(env)
		table.insert(env_menu, Menu.item(env))
	end
	return env_menu
end

local function creat_env_menu()
	local env_items = env_menu_items()
	return Menu({
		position = "50%",
		border = {
			style = "single",
			text = {
				top = "[Select env]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		lines = env_items,
		max_width = 200,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>" },
			submit = { "<CR>", "<Space>" },
		},
		on_close = function()
			print("Cancelled env selection")
		end,
		on_submit = function(item)
			print("Activating env: ", item.text)
			M.current_env = item.text
		end,
	})
end

function M.env_menu()
	creat_env_menu():mount()
end

return M
