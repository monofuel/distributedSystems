require('schema')

-- Key Value Store

KV_Schema = {
    type = "KV",
    fields = {
        {
            name = 'collection',
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
    KV_Store.collections = {}
    KV_Store.WAL = {}
end

--[[
    commands:
    PING
    SET key value ttl
    GET key
    DELETE key
]]

function KV_Store:exec(cmd)
end


