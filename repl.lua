require('./kv')
require('./logging')

function repl()
    local store = KV_Store:new({ name = 'test2', reset = false})
    io.write('> ')
    for line in io.lines() do
        if line == 'exit' then
            break
        end
        local res = store:exec(line)
        print(res)
        io.write('> ')
    end

end

repl()
