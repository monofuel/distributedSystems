require('./schema')
require('./util')
-- Key Value Store

KV_Schema = {
    type = "KV",
    fields = {
        {
            name = 'tables',
            id = 1,
            repeated = true,
            type = {
                type = "tableT",
                fields =  {
                    {
                        name = 'name',
                        id = 1,
                        repeated = false,
                        type = 'string'
                    },
                    {
                        name = 'entries',
                        id = 2,
                        repeated = true,
                        type = {
                            type = 'entryT',
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
    store.name = name
    return store
end

--[[
    commands:
    PING
    SET key value ttl
    GET key
    DELETE key
]]

-- TODO parsing complex values
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

-- commit a WAL event to the log, and mutate internal state
function KV_Store:writeWAL(ev)

    local buf = encode(ev, WAL_Schema)
    local wal_filepath = './test_db/' .. self.name .. '.wal'
    local wal_file = io.open(db_filepath, 'a')
    wal_file:write(buf)
end

function KV_Store:flush()
    local tables = {}
    for name, entries in pairs(self.tables) do
        table.insert(tables, {
            name = name,
            entries = entries
        })
    end

    local buf = encode({ tables = tables }, KV_Schema)
    local db_filepath = './test_db/' .. self.name .. '.bin'
    local db_file = io.open(db_filepath, 'w+')
    db_file:write(buf)
end
