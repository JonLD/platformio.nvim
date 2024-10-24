M = {}

function M.register()
    vim.api.nvim_create_user_command("Pio", function(args)
        require("platformio.pioterm").piocmd(args.fargs)
    end, { nargs = "*", desc = "Pass PlatformIO CLI commands" })
    vim.api.nvim_create_user_command("Pioinit", function()
        require("platformio.pioinit").pioinit()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("Piorun", function(args)
        require("platformio.piorun").piorun(unpack(args.fargs))
    end, { nargs = "*" })
    vim.api.nvim_create_user_command("Piolib", function(args)
        require("platformio.piolib").piolib(unpack(args.fargs))
    end, { nargs = "*" })
    vim.api.nvim_create_user_command("Piomon", function(args)
        require("platformio.piomon").piomon(unpack(args.fargs))
    end, { nargs = "*" })
    vim.api.nvim_create_user_command("Piodebug", function()
        require("platformio.piodebug").piodebug()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("Pioenv", function()
        require("platformio.pioenv").pioenv()
    end, { nargs = 0 })
end

return M
