require("./schema")
require("./util")
require('./logging')

-- Write Ahead Log

WAL_Kinds = {
    noop = 0,
    doom = 1,
    create = 2,
    -- ['patch'] = 3,
    delete = 4
}

WAL_Schema = {
    ["type"] = "WAL",
    ["fields"] = {
        {
            ["name"] = "ID",
            ["id"] = 1,
            ["type"] = "uuid"
        },
        {
            -- WAL_Kinds
            ["name"] = "kind",
            ["id"] = 2,
            -- TODO this could be 1 byte?
            ["type"] = "integer"
        },
        -- TODO a union format would be nice in the future
        {
            ["name"] = "bytes",
            ["id"] = 3,
            ["type"] = "string"
        }
    }
}
validateSchema(WAL_Schema)


function handle_wal_event(ev)
    if ev['kind'] == WAL_Kinds.noop then
        info("NOOP Event: " .. tohex(ev['ID']))
        return
    elseif ev['kind'] == WAL_Kinds.doom then
        assert(false, "DOOM")
    else   
        print("ev handler not implemented: " .. ev.kind)
    end
end
