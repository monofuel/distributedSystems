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
    store.tables = {
        default = {}
    }
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
    if tokens[1] == 'PING' then
        if (tokens[2]) then
            return tokens[2]
        else
            return 'PONG'
        end
    elseif tokens[1] == 'SET' then
        local tab = self.tables.default;
        local key = tokens[2]
        local value = tokens[3]
        -- TODO WAL
        tab[key] = value
        return 'SET ' .. key
    elseif tokens[1] == 'GET' then
        local tab = self.tables.default;
        local key = tokens[2]
        local value = tab[key]
        return value
        
    elseif tokens[1] == 'DELETE' then
        local tab = self.tables.default;
        local key = tokens[2]
        -- TODO WAL
        tab[key] = nil
        return 'DEL ' .. key
    else
        return 'unknown command: ' .. tokens[1]
    end
end


