require('./encoder')

function test()

    assertEqual(intToBytes(5) , fromhex('05000000'))
    
    assertEqual(doubleToBytes(5.5), fromhex('0000000000001640'))

    assertEqual(encode(5), fromhex('0305000000'))
    assertEqual(encode("abc"), fromhex('1003000000616263'))
    assertEqual(decode(fromhex('00')), nil)
    assertEqual(decode(fromhex('100100000061')), 'a')
    assertEqual(decode(fromhex('1003000000616263')), 'abc')
    assertEqual(encode("value_str"), fromhex('100900000076616C75655F737472'))

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
        print("| " .. k .. " : " .. tohex(buf))
        local dec = decode(buf)
        -- assert v == dec for basic types
        assertEqual(v, dec)
       
    end

    local tables = {
        {
            ["key_str"] = "value_str"
        },
        {
            ['num_str'] = 5,
            ["key_str"] = "value_str",
            ["other_key_str"] = "value_str2"
        },
        {
            ['num'] = 5,
            ['foo'] = 5.32,
            ['nil_val'] = nil,
            ["key_str"] = "value_str"
        },
        {
            ['num'] = 5,
            ['foo'] = 5.32,
            ['nexted'] = {
                ['qwerty'] = 'uiop;',
                ['num'] = 5,
                ['nil_val'] = nil,
            },
            ["key_str"] = "value_str"
        }
    
    }
    for k,v in pairs(tables) do
        local buf = encode(v)
        print("| " .. k .. " : " .. tohex(buf))
        -- should load tables without schema
        -- will be missing keys
        decode(buf)
       
    end
end


test()
