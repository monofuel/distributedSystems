require('./util')

-- lua types:
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
-- uuid - 0x05
--   128 bit UUID
-- string - 0x10
--   4 byte integer for size of string
-- record - 0x11
--   4 byte integer for # of bytes for table
--   if a record has the key 1 it is assumed to be an array
--     arrays must be stored in a record (cannot be top-level) 
--   each entry in the record has a 1 byte ID for the key
--   followed by an encoded value.
--   Arrays are represented by repeating a record key multiple times
-- binary - 0x12
--   4 byte integer for size of binary array (essentially like string)


local typeC = {
    ["nil"] = string.char(0x00),
    ["integer"] = string.char(0x03),
    ["double"] = string.char(0x04),
    ["uuid"] = string.char(0x05),
    ["string"] = string.char(0x10),
    ["record"] = string.char(0x11),
    ["binary"] = string.char(0x12),
}


-- returns a string of encoded bytes
function encode(v, schema)
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
    elseif schema == 'uuid' then
        local buf = typeC['uuid']
        assertEqual(string.len(v), 16)
        buf = buf .. v
        return buf
    elseif typeOf == 'string' and schema == 'binary' then
        local buf = typeC['binary']
        local length = intToBytes(string.len(v))
        buf = buf .. length
        return buf .. v
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
            local field
            local key_code
            -- find the field in the schema
            if (schema ~= nil) then
                for k5, v5 in pairs(schema['fields']) do
                    if k == v5['name'] then
                        field = v5
                    end
                end
                if field == nil then
                    error('could not find ID for key: '.. k)
                end
                key_code = string.char(field['id'])
            else
                keyId = keyTab[k]
                if keyId == nil then
                    keyCount = keyCount + 1
                    keyId = keyCount
                    keyTab[k] = keyCount
                end

                key_code = string.char(keyId)
            end
            -- append values to buffer
           
            -- TODO need to know schema to assign IDs for keys

            -- if a schema isn't provided, assign IDs in order
            
            local sub_schema = nil
            if field ~= nil then
                sub_schema = field['type']
            end

            local is_array = type(v2) == 'table' and v2[1] ~= nil
            if (is_array) then
                for k3, v3 in pairs(v2) do
                    local value_buf = encode(v3, sub_schema)
                    record = record .. key_code .. value_buf
                end
            else
                local value_buf = encode(v2, sub_schema)
                record = record .. key_code .. value_buf
            end
            

        end
        
        local length = intToBytes(string.len(record))
      
        return code .. length .. record
    else
        error('Unsupported Type: ' .. typeOf)
    end

end

-- takes in an encoded string of bytes and returns the value
function decode(buf, schema)
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
    elseif code == typeC['uuid'] then
        if string.len(buf) ~= 16 then
            error("Expected 16 bytes for uuid, found " .. string.len(buf))
        end
        return buf
    elseif code == typeC['string'] or code == typeC['binary'] then
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
        local tab = {}
        while string.len(recBuf) > 0 do
            -- if a schema is provided, use it to convert IDs to keys
            -- otherwise use keys
            local key = string.unpack("b", recBuf)
            local sub_schema = nil
            local repeated = false
            if schema ~= nil then
                for k, v in pairs(schema['fields']) do
                    if v['id'] == key  then
                        key = v['name']
                        repeated = v['repeated']
                        sub_schema = v['type']
                        break
                    end
                end
            end

            -- chomp off bytes based on type
            local typeCode = string.sub(recBuf, 2, 2)
            local length = 0;
            if (typeCode == typeC['nil']) then
                length = 0
            elseif (typeCode == typeC['integer']) then
                length = 4
            elseif (typeCode == typeC['double']) then
                length = 8
            elseif (typeCode == typeC['uuid']) then
                length = 16
            elseif(typeCode >= fromhex('10')) then
                -- chomp off ${length} bytes
                -- chomp chomp chomp chomp
                local lengthBuf = string.sub(recBuf, 3, 6)
                -- add 4 for the size of int
                length = string.unpack("i", lengthBuf) + 4
            else
                error('unknown type code ' .. tohex(typeCode))
            end

            -- add 1 for key ID, and 1 for type code
            length = length + 2
            local subBuf = string.sub(recBuf, 2, length)
            -- TODO pass sub schema through
            
            -- if tab[key] already has a value, handle it as an array
            if (tab[key] ~= nil or repeated ) then
  
                local val =  decode(subBuf, sub_schema)
                -- check if it is already a table
                if tab[key] == nil then
                    -- if schema is repeated and table does not exist
                    tab[key] = {
                        val
                    }
                elseif (repeated or (type(tab[key]) == 'table' and tab[key][1] ~= nil)) then
                    -- if table exists
                    -- logDebug(toPrettyPrint(tab))
                    table.insert(tab[key], val)
                else
                    -- if it is a value
                    local old_val = tab[key]
                    tab[key] = {
                        old_val,
                       val
                    }

                end
            else
                tab[key] = decode(subBuf, sub_schema)
            end
            recBuf = string.sub(recBuf, 1 + length)
        end
        return tab
    else
        error('Unsupported Type: ' .. tohex(code))
    end

    
end
