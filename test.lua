require('./encoder')
require('./schema')

function test()

    assertEqual(intToBytes(5) , fromhex('05000000'))
    
    assertEqual(doubleToBytes(5.5), fromhex('0000000000001640'))

    assertEqual(encode(5), fromhex('0305000000'))
    assertEqual(encode("abc"), fromhex('1003000000616263'))
    assertEqual(decode(fromhex('00')), nil)
    assertEqual(decode(fromhex('100100000061')), 'a')
    assertEqual(decode(fromhex('1003000000616263')), 'abc')
    assertEqual(encode("value_str"), fromhex('100900000076616C75655F737472'))
    assertEqual(encode({ ['arr'] = { 1, 2, 3}}), fromhex('1112000000010301000000010302000000010303000000'))
    
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
            ['nil_val'] = nil, -- TODO how to handle nil values?
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
        },
        {
            ['arr'] = {
                1,
                2,
                3,
                4,
            }
        }
    
    }
    for k,v in pairs(tables) do
        local buf = encode(v)
        print("| " .. k .. " : " .. tohex(buf))
        -- should load tables without schema
        -- will be missing keys
        local dec = decode(buf)
        -- TODO validate dec
    end


    local testSchema1 = {
        ['type'] = 'foo',
        ['fields']= {
            {
                ['name'] = 'bar1',
                ['repeated'] = false,
                ['type']= 'string',
                ['id'] = 1,
            },
            {
                ['name']= 'num1',
                ['repeated']= false,
                ['type']= 'integer',
                ['id'] = 2,
            },
            {
                ['name']= 'num2',
                ['repeated']= false,
                ['type']= 'double',
                ['id'] = 3,
            }
        }
    }
    validateSchema(testSchema1)
    encode({
        ['bar1']= 'stuff',
        ['num1']= 5,
        ['num2']= 3.3333,
    }, testSchema1)
end


test()
