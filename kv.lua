require('./schema')
require('./wal')
require('./util')
require('./encoder')

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
function KV_Store:new(args)
    local name = args.name
    local reset = args.reset == true

    local store = setmetatable({}, { __index = KV_Store })
    store.tables = {
        default = {}
    }
    store.WAL = {}
    store.name = name

    store.wal_filepath = './test_db/' .. store.name .. '.wal'
    store.db_filepath = './test_db/' .. store.name .. '.bin'

    if reset == true then
        store.wal_file = io.open(store.wal_filepath, 'w')
        store.db_file = io.open(store.db_filepath, 'w')
    else 
        store.wal_file = io.open(store.wal_filepath, 'a')
        store.db_file = io.open(store.db_filepath, 'w')
        -- TODO
        -- load DB and wal from file

    end

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
        self:writeWAL('set', {
            key = key,
            value = encode(value),
        })
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
function KV_Store:writeWAL(kind, value)

    -- TODO kind schemas
    local schema = WAL_Schemas[kind]
    if schema == nil then
        error('unknown schema: ' .. kind)
    end
    local value_buf = encode(value, schema)
    local buf = encode({
        ID = gen_uuid(),
        kind = WAL_Kinds[kind],
        bytes = value_buf
    }, WAL_Schema)
    self.wal_file:write(buf)
    self.wal_file:flush()
    -- TODO mutate state
end

function KV_Store:flush()
    local tables = {}
    for name, tab in pairs(self.tables) do
        local entries = {}
        for k, v in pairs(tab) do
            table.insert(entries, {
                key = k,
                value = v
            })
        end
        table.insert(tables, {
            name = name,
            entries = entries
        })
    end

    local buf = encode({ tables = tables }, KV_Schema)
    self.db_file:write(buf)
    self.db_file:flush()
end

function KV_Store:close()
    self:flush()

    self.wal_file:close()
    self.db_file:close()
end
