require('./kv')
require('./logging')
require('./util')

function startServer()
    local options = parseArgs()
    local store = KV_Store:new(options)
    logInfo('starting server: ' .. options.role)
    if options.role == 'leader' then

        local listen_routine = store:listen()
        while 1 do
            coroutine.resume(listen_routine)
        end
    else
        local follow_routine = store:follow()
        local repl_routine = store:listen()
        while 1 do
            coroutine.resume(follow_routine)
            coroutine.resume(repl_routine)
        end
    end
end

startServer()
