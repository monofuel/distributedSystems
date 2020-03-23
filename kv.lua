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
                        name = 'state',
                        id = 3,
                        repeated = false,
                        type = 'number'
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
    local in_memory = args.in_memory == true


    local store = setmetatable({}, { __index = KV_Store })
    store.tables = {
        default = {}
    }
    store.table_state = {
        default = 0
    }
    store.WAL = {}
    store.name = name
    store.__in_memory = in_memory

    store.wal_filepath = './test_db/' .. store.name .. '.wal'
    store.db_filepath = './test_db/' .. store.name .. '.bin'
    if not in_memory then
        logDebug("backing db by file")
        if reset == true then
            logDebug("resetting DB")
            store.wal_file = io.open(store.wal_filepath, 'wb')
            store.db_file = io.open(store.db_filepath, 'wb')
        else 
            logDebug("reading in DB state from disk")
            -- TODO read in WAL
            store.wal_file = io.open(store.wal_filepath, 'ab')
            store.db_file = io.open(store.db_filepath, 'rb')
            

            local db_buf = nil
            if store.db_file ~= nil then
                db_buf = store.db_file:read("*a")
            end
            if db_buf ~= nil then
                local db = decode(db_buf, KV_Schema)

                for k1, v1 in pairs(db.tables) do
                    local name = v1.name
                    local entries = v1.entries
                    store.table_state[name] = v1.state

                    store.tables[name] = {}
                    local tab = store.tables[name]
                    for k2, v2 in pairs(entries) do
                        local key = v2.key
                        local value = v2.value
                      
                        tab[key] = value
                    end
                end
            end

            store:replayWAL()
            
            -- re-open DB file for writing
            if store.db_file ~= nil then
                store.db_file:close()
            end
            store.db_file = io.open(store.db_filepath, 'ab')
            store.db_file:seek("set")
        end
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
        local value_str = tokens[3]
        local value = nil
        

        if string.match(value_str, "^[0-9]+$") or string.match(value_str, "^[0-9]+\\.[0-9]+$") then -- Integer or floating point
            value = encode(tonumber(value_str))
        elseif string.match(value_str, "^0x[0-9a-fA-F]+$") then -- hex
            local buf = fromhex(value_str:sub(3))
            value = encode(buf, 'binary')
        else
            value = encode(value_str)
        end

        self:writeWAL('set', {
            key = key,
            table = 'default',
            value = value,
        })
       
        return 'SET ' .. key
    elseif tokens[1] == 'GET' then
        local tab = self.tables.default;
        local key = tokens[2]
        local value = tab[key]
        if value == nil then
            return nil
        end
        
        local code = string.sub(value,1,1)
     
        value = decode(value)
        if code == string.char(0x12) then
            return '0x' .. tohex(value)
        else 
            return value
        end
        
    elseif tokens[1] == 'DELETE' then
        local tab = self.tables.default;
        local key = tokens[2]
        self:writeWAL('delete', {
            key = key,
            table = 'default',
        })
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
    
    local state = self.table_state[value.table] + 1
    self.table_state[value.table] = state

    local value_buf = encode(value, schema)
    local buf = encode({
        ID = state,
        kind = WAL_Kinds[kind],
        bytes = value_buf
    }, WAL_Schema)
    if not self.__in_memory then
        self.wal_file:write(buf)
        self.wal_file:flush()
    end
    self:handleWAL(kind, value)
end

function KV_Store:replayWAL()

    -- TODO

    -- check if the DB is in check with the WAL
    -- catch up DB to WAL if behind
end

function KV_Store:handleWAL(kind, ev)

    if kind == 'set' then
        local tab = self.tables[ev.table]
        tab[ev.key] = ev.value
    elseif kind == 'delete' then
        local tab = self.tables[ev.table]
        tab[ev.key] = nil
    else
        error('event not implemented: ' .. kind)
    end
end

function KV_Store:flush()
    if self.__in_memory then
        logDebug("Skipping flush for in-memory DB")
        return
    end
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
    -- TODO could write to a new file, then swap them to prevent corruption from incomplete writes
    self.db_file:close()
    self.db_file = io.open(self.db_filepath, 'w')
    self.db_file:write(buf)
    self.db_file:flush()
end

function KV_Store:close()
    self:flush()
    if not self.__in_memory then
        self.wal_file:close()
        self.db_file:close()
    end
end
