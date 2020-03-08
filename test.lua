require('./encoder')
require('./schema')
require('./wal')
require('./kv')
require('./logging')

function test()

    assertEqual(intToBytes(5) , fromhex('05000000'))
    
    assertEqual(doubleToBytes(5.5), fromhex('0000000000001640'))

    assertEqual(encode(5), fromhex('0305000000'))
    assertEqual(encode("abc"), fromhex('1003000000616263'))
    assertEqual(decode(fromhex('00')), nil)
    assertEqual(decode(fromhex('100100000061')), 'a')
    assertEqual(decode(fromhex('1003000000616263')), 'abc')
    assertEqual(encode("value_str"), fromhex('100900000076616C75655F737472'))
    assertEqual(encode({ arr = { 1, 2, 3}}), fromhex('1112000000010301000000010302000000010303000000'))
    
    local testData = {
        5,
        100,
        10.5,
        3.333,
        6.666,
        "a",
        "abc",
        "ascii"
    }
    for k,v in pairs(testData) do
        local buf = encode(v)
        info(k .. " : " .. tohex(buf))
        local dec = decode(buf)
        -- assert v == dec for basic types
        assertEqual(v, dec)
       
    end

    local tables = {
        {
            key_str = "value_str"
        },
        {
            num_str = 5,
            key_str = "value_str",
            other_key_str = "value_str2"
        },
        {
            num = 5,
            foo = 5.32,
            nil_val = nil, -- TODO how to handle nil values?
            key_str = "value_str"
        },
        {
            num = 5,
            foo = 5.32,
            nexted = {
                qwerty = 'uiop;',
                num = 5,
                nil_val = nil,
            },
            key_str = "value_str"
        },
        {
            arr = {
                1,
                2,
                3,
                4,
            }
        }
    
    }
    for k,v in pairs(tables) do
        local buf = encode(v)
        info( k .. " : " .. tohex(buf))
        -- should load tables without schema
        -- will be missing keys
        local dec = decode(buf)
        -- TODO validate dec
    end


    local testSchema1 = {
        type = 'foo',
        fields = {
            {
                name = 'bar1',
                repeated = false,
                type = 'string',
                id = 5,
            },
            {
                name = 'num1',
                repeated = false,
                type = 'integer',
                id = 10,
            },
            {
                name = 'num2',
                repeated = false,
                type = 'double',
                id = 18,
            }
        }
    }
    validateSchema(testSchema1)
    local buf = encode({
        bar1 = 'stuff',
        num1 = 5,
        num2 = 3.3333,
 
     }, testSchema1)
     info(tohex(buf))

     -- print(decode(buf))

    -- assertEqual(buf,
    -- decode(fromhex('111D0000003510050000007374756666313804ED0DBE3099AA0A4031300305000000')), testSchema1)


    local id = gen_uuid()
    info("UUID: " .. tohex(id))
    assertEqual(string.len(id), 128 / 8)

    local wal_noop = {
        ID = gen_uuid(),
        kind = WAL_Kinds.noop,
        bytes = ""
    }
    local wal_buf = encode(wal_noop, WAL_Schema)
    info('WAL ' .. tohex(wal_buf))
    local wal_ev = decode(wal_buf, WAL_Schema)
    assertEqual(wal_ev.ID, wal_noop.ID)
    assertEqual(wal_ev.kind, 0)
    assertEqual(wal_ev.bytes, "")
    handle_wal_event(wal_ev)

    local store = {
        collection = {
            {
                key = 'foo',
                value = 'bar'
            },
            {
                key = 'foo2',
                value = 5
            },
            {
                key = 'foo3',
                value = 5.44
            }
        }
    }
    local store_buf = encode(store, KV_Schema)
    info(tohex(store_buf))
    local store_dec = decode(store_buf, KV_Schema)
    local count = 0
    info(toPrettyPrint(store_dec))
    for k, v in pairs(store_dec.collection) do
        count = count + 1
    end
    assertEqual(count, 3)

end

function io_test()

    local db_name = 'test'
    local dir = './test_db'
    local wal_filepath = dir .. '/' .. db_name .. '.wal'
    -- local db_filepath = dir .. '/' .. db_name .. '.bin'


    local wal = {
        {
            ID = gen_uuid(),
            kind = WAL_Kinds.noop,
            bytes = ""
        },
        {

            ID = gen_uuid(),
            kind = WAL_Kinds.create,
            bytes = ""
        }
    }

    local wal_buf = ""
    for k, v in ipairs(wal) do
        local buf = encode(v, WAL_Schema)
        wal_buf = wal_buf .. buf
    end

    local wal_file = io.open(wal_filepath, "w+")
    -- local db_file = io.open(db_filepath, "w+")

    info(tohex(wal_buf))
    wal_file:write(wal_buf)


end

function db_test()
    local store = KV_Store:new('test1')
end

test()
io_test()
db_test()
