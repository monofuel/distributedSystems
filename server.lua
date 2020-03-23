require('./kv')
require('./logging')
require('./util')

function startServer()
    local options = parseArgs()
    local store = KV_Store:new(options)
    store:listen()
end

startServer()
