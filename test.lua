require('./encoder')
require('./schema')
require('./wal')
require('./kv')
require('./logging')
require('./util')

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
        logInfo(k .. " : " .. tohex(buf))
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
        logInfo( k .. " : " .. tohex(buf))
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
     logInfo(tohex(buf))

     -- print(decode(buf))

    -- assertEqual(buf,
    -- decode(fromhex('111D0000003510050000007374756666313804ED0DBE3099AA0A4031300305000000')), testSchema1)


    local id = gen_uuid()
    logInfo("UUID: " .. tohex(id))
    assertEqual(string.len(id), 128 / 8)

    local wal_noop = {
        ID = 1,
        kind = WAL_Kinds.noop,
        bytes = ""
    }
    local wal_buf = encode(wal_noop, WAL_Schema)
    logInfo('WAL ' .. tohex(wal_buf))
    local wal_ev = decode(wal_buf, WAL_Schema)
    assertEqual(wal_ev.ID, wal_noop.ID)
    assertEqual(wal_ev.kind, 0)
    assertEqual(wal_ev.bytes, "")
    handle_wal_event(wal_ev)

    local store = {
        tables = {
            {
                name = 'default',
                entries = {
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
        }
    }
    local store_buf = encode(store, KV_Schema)
    logInfo(tohex(store_buf))
    local store_dec = decode(store_buf, KV_Schema)
    logInfo(toPrettyPrint(store_dec))
    assertEqual(store_dec.tables[1].name, 'default')
    assertEqual(#store_dec.tables[1].entries, 3)

end

function io_test()

    local db_name = 'test'
    local dir = './test_db'
    local wal_filepath = dir .. '/' .. db_name .. '.wal'
    -- local db_filepath = dir .. '/' .. db_name .. '.bin'


    local wal = {
        {
            ID = 1,
            kind = WAL_Kinds.noop,
            bytes = ""
        },
        {

            ID = 2,
            kind = WAL_Kinds.create,
            bytes = ""
        }
    }

    local wal_buf = ""
    for k, v in ipairs(wal) do
        local buf = encode(v, WAL_Schema)
        wal_buf = wal_buf .. buf
    end

    local wal_file = io.open(wal_filepath, "wb")
    -- local db_file = io.open(db_filepath, "wb")

    logInfo(tohex(wal_buf))
    wal_file:write(wal_buf)


end

function db_test()
    local store = KV_Store:new({ name = 'test1', reset = true})
    local res = ''
    res = store:exec("PING")
    assertEqual(res, "PONG")

    res = store:exec('PING "hello world"')
    assertEqual(res, '"hello world"')

    res = store:exec("GET foo")
    assertEqual(res, nil)

    res = store:exec("SET foo \"hello world\"")
    assertEqual(res, "SET foo")

    res = store:exec("GET foo")
    assertEqual(res, "\"hello world\"")

    res = store:exec("DELETE foo")
    assertEqual(res, "DEL foo")

    res = store:exec("GET foo")
    assertEqual(res, nil)

    res = store:exec("SET foo2 \"hello world!\"")
    assertEqual(res, "SET foo2")

    -- TODO test that it's stored internally as binary
    res = store:exec("SET hex 0x123456")
    res = store:exec("GET hex")
    assertEqual(res, "0x123456")

    local listen_routine = store:listen()
    coroutine.resume(listen_routine)

    store:flush()
    store:close()

    -- load DB back in
    local store2 = KV_Store:new({ name = 'test1', reset = false })
    res = store2:exec("GET foo2")
    assertEqual(res, "\"hello world!\"")
    store2:close()

    -- -- TODO test WAL when saving/loading
    -- local store3 = KV_Store:new({ name = 'test3', reset = true })
    -- store3.exec('SET foo3 "Hello World"' )
    -- -- foo
    -- local value_buf = encode({
    --     key = 'foo3',
    --     value = encode('Hello World 2'),
    --     table = 'default'
    -- }, WAL_Schemas[set])
    -- local buf = encode({
    --     ID = 2,
    --     kind = 'set',
    --     bytes = value_buf
    -- }, WAL_Schema)
    -- store.wal_file:write(buf)
    -- store.wal_file:flush()

    -- TODO test loading
    -- stuff
end

function token_test()

    local res = ''
    res = tokenize("PING")
    assertEqual(res, { "PING" })
    res = tokenize('PING "hello world"')
    assertEqual(res, { "PING", "\"hello world\"" })
    res = tokenize('GET foobar')
    assertEqual(res, { "GET", "foobar" })

    res = tokenize('SET foo bar')
    assertEqual(res, { "SET", "foo", "bar" })
    res = tokenize('SET foo "hello world"')
    assertEqual(res, { "SET", "foo", "\"hello world\"" })
end

test()
io_test()
token_test()
db_test()
