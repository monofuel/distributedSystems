require('./kv')
require('./logging')
require('./util')

function repl()
    -- TODO EXIT and RESET should be handled by KV store

    local options = parseArgs()
    if options.remote then
        local socket = require('socket')

        local client, err = socket.connect(options.remote, options.repl_port)
        client:settimeout(60)
        if err then
            error('failed to connect to server: ' .. err)
        end
        logInfo('connected to server!')

        -- TODO connect
        io.write('> ')
        for line in io.lines() do
            if line == 'EXIT' then
                break
            else
                client:send(line .. '\n')
                local line, error = client:receive('*l')
                if err then
                    error('client receive error: ' .. err)
                end
                print(line)
            end
            io.write('> ')
        end
    else
        
        local store = KV_Store:new(options)
        io.write('> ')
        for line in io.lines() do
            if line == 'EXIT' then
                break
            elseif line == 'RESET' then
                options.reset = true
                store = KV_Store:new(options)
            else
                local res = store:exec(line)
                print(res)
            end
            io.write('> ')
        end
        store:close()
    end
    
end

repl()
