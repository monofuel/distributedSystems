require('schema')

-- Key Value Store

KV_Schema = {
    type = "KV",
    fields = {
        {
            name = 'table',
            id = 1,
            repeated = true,
            type = {
                type = 'entry',
                fields = {
                    {
                        name = "key",
                        id = 1,
                        type = "string"
                    },
                    {
                        name = "value",
                        id = 2,
                        type = "any"
                    }
                }
            }
        }
    }
}
validateSchema(KV_Schema)

KV_Store = {}
function KV_Store:new(name)
    local store = setmetatable({}, { __index = KV_Store })
    store.tables = {}
    store.WAL = {}
    return store
end

--[[
    commands:
    PING
    SET key value ttl
    GET key
    DELETE key
]]

function KV_Store:exec(cmd)
    local tokens = tokenize(cmd)
    if #tokens == 0 then
        error('invalid number of tokens')
    end
    if tokens[0] == 'PING' then
        return 'PONG'
    end
end


