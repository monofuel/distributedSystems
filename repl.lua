require('./kv')
require('./logging')

function repl()
    local store = KV_Store:new({ name = 'test2', reset = false})
    io.write('> ')
    for line in io.lines() do
        if line == 'exit' then
            break
        elseif line == 'reset' then
            store = KV_Store:new({ name = 'test2', reset = true })
        else
            local res = store:exec(line)
            print(res)
        end
        io.write('> ')
    end
    store:close()

end

repl()
