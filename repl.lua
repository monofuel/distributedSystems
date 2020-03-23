require('./kv')
require('./logging')
require('./util')

function repl()
    local options = parseArgs()
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

repl()
