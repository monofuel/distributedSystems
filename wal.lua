require("./schema")
require("./util")
require('./logging')

-- Write Ahead Log

WAL_Kinds = {
    noop = 0,
    doom = 1,
    set = 2,
    -- ['patch'] = 3,
    delete = 4
}

-- TODO should refactor WAL_Kinds to be something reasonable
function getNameForWALKind(kind)
    for k, v in pairs(WAL_Kinds) do
        if kind == v then
            return k
        end
    end
end

WAL_Schema = {
    type = "WAL",
    fields = {
        {
            name = "ID",
            id = 1,
            type = "integer"
        },
        {
            -- WAL_Kinds
            name = "kind",
            id = 2,
            -- TODO this could be 1 byte?
            type = "integer"
        },
        -- TODO a union format would be nice in the future
        {
            name = "bytes",
            id = 3,
            type = "string"
        }
    }
}
validateSchema(WAL_Schema)

WAL_Set_Schema = {
    type = 'WAL_Set',
    fields = {
        {
            name = 'key',
            id = 1,
            type = 'string'
        },
        {
            name = 'value',
            id = 2,
            type = 'string' -- encoded bytes
        },
        {
            name = "table",
            id = 3,
            type = "string"
        }
    }
}
validateSchema(WAL_Set_Schema)

WAL_Delete_Schema = {
    type = 'WAL_Delete',
    fields = {
        {
            name = 'key',
            id = 1,
            type = 'string'
        },
        {
            name = "table",
            id = 2,
            type = "string"
        }
    }
}
validateSchema(WAL_Delete_Schema)


WAL_Schemas = {
    set = WAL_Set_Schema,
    delete = WAL_Delete_Schema
}


function handle_wal_event(ev)
    if ev['kind'] == WAL_Kinds.noop then
        logInfo("NOOP Event: " .. ev['ID'])
        return
    elseif ev['kind'] == WAL_Kinds.doom then
        assert(false, "DOOM")
    else   
        print("ev handler not implemented: " .. ev.kind)
    end
end
