local M = {}

local http = require("socket.http")
local ltn12 = require("ltn12")

function M.piolib(lib_arg_list)
    json_str = ""
    lib_str = ""
    local lib_name = {}
    local lib_data = {}
    local resp= {}

    for k,v in pairs(lib_arg_list) do
        lib_str = lib_str .. v 
    end

    url = 'https://api.registry.platformio.org/v3/search?query=%22' .. lib_str .. '%22&page=1&limit=50'

    client, code, headers, status = http.request{url=url, sink=ltn12.sink.table(resp), method="GET"}

    if (code == 200) then

        for k,v in pairs(resp) do
            json_str = json_str .. v
        end

        local json_data = require('lunajson').decode(json_str)

        for k,v in pairs(json_data['items']) do
            lib_data[v['name']] = v
            table.insert(lib_name, v['name'])
        end

        -- print(vim.inspect(lib_data))
        print(vim.inspect(lib_name))
    end
end

M.piolib({'Arduino', 'Json'})

return M
