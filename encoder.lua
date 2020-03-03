require('./util')

-- Schema
--  "nil" | "number" | "string" | "boolean" | "table" | "function" | "thread" | "userdata"

-- for each value:
-- first byte for KEY
-- second byte is TYPE

-- should types be in the encoded binary, or assumed based on key?
--   how about unions?
--   should it require a schema to load?
--   how about no for now

-- arrays are expressed by including a key multiple times
-- all types lower than 0x10 are constant-size
-- all types equal or higher than 0x10 are followed by
--   an integer specifying size

-- Type codes:
-- nil - 0x00
--   no value
-- true boolean - 0x01
--   no value
-- false boolean - 0x02
--   no value
-- number (integer) - 0x03
--   constant size (4 byte integer)
-- number (double) - 0x04
--   constant size (8 byte double precision floating point)
-- string - 0x10
--   4 byte integer for size of string
-- record - 0x11
--   4 byte integer for # of bytes for table

local typeC = {
    ["nil"] = string.char(0x00),
    ["integer"] = string.char(0x03),
    ["double"] = string.char(0x04),
    ["string"] = string.char(0x10),
    ["record"] = string.char(0x11)
}


-- returns a string of encoded bytes
function encode(v)
    local typeOf = type(v)
    if typeOf == 'nil' then
        return typeC['nil']
    elseif typeOf == 'number' then
        if (math.type(v) == 'float') then
            local buf = typeC['double']
            buf = buf .. doubleToBytes(v)
            return buf
        elseif (math.type(v) == 'integer') then
            local buf = typeC['integer']
            buf = buf .. intToBytes(v)
            return buf
        else
            error('invalid number type for ' .. v)
        end
        
    elseif typeOf == 'string' then
        local buf = typeC['string']
        local length = intToBytes(string.len(v))
        buf = buf .. length
        return buf .. v
    elseif typeOf == 'table' then
        local code = typeC['record']

        local record = ''
        
        local keyCount = 0
        local keyTab = {}

        for k, v2 in pairs(v) do
            -- append values to buffer
            -- TODO handle arrays
            -- TODO need to know schema to assign IDs for keys

            keyId = keyTab[k]
            if keyId == nil then
                keyCount = keyCount + 1
                keyId = keyCount
                keyTab[k] = keyCount
            end

            local key_code = string.char(keyId)

            local value_buf = encode(v2)
            record = record .. key_code .. value_buf
        end

           local length = intToBytes(string.len(record))
        return code .. length .. record
    else
        error('Unsupported Type: ' .. typeOf)
    end

end

-- takes in an encoded string of bytes and returns the value
function decode(buf)
    if string.len(buf) < 1 then
        error('cannot decode empty buffer')
    end
    local code = string.sub(buf,1,1)
    buf = string.sub(buf,2)

    if code == typeC['nil'] then
        return nil
    elseif code == typeC['integer'] then
        if string.len(buf) ~= 4 then
            error("Expected 4 bytes for int, found " .. string.len(buf))
        end
        return string.unpack("i", buf)
    elseif code == typeC['double'] then
        if string.len(buf) ~= 8 then
            error("Expected 8 bytes for double, found " .. string.len(buf))
        end
        return string.unpack("d", buf)
    elseif code == typeC['string'] then
        local sub = string.sub(buf, 1, 4)
        local length = string.unpack("i", string.sub(buf, 1, 4))
        
        local strBuf = string.sub(buf, 5)
        if (string.len(strBuf) ~= length) then
            error("Expected " .. length .. " bytes for string, found " .. string.len(strBuf))
        end
        return string.unpack("c"..length, strBuf)
    elseif code == typeC['record'] then
        local length = string.unpack("i", string.sub(buf, 1, 4))
        local recBuf = string.sub(buf, 5)
        if (string.len(recBuf) ~= length) then
            error("Expected " .. length .. " bytes for record, found " .. string.len(recBuf))
        end
        return nil
    else
        error('Unsupported Type: ' .. tohex(code))
    end

    
end
