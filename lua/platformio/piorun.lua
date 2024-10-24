local M = {}

local utils = require("platformio.utils")
local pioenv = require("platformio.pioenv")

function M.pioruncmd(target)
    utils.cd_pioini()
    local target_flag = ""
    if target ~= "build" then
        target_flag = "--target " .. target
    end
    local command = "pio run " .. target_flag .. " " .. pioenv.cmd_env_flag() .. utils.extra
    utils.ToggleTerminal(command, "float")
end

function M.piorun(arg)
    if not utils.pio_install_check() then
        return
    end

    if arg == nil then
        arg = "upload"
    end

    arg = utils.strsplit(arg, "%s")[1]
    M.pioruncmd(arg)
end

return M
