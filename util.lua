
function assertEqual(v1, v2)
    local t1 = type(v1)
    local t2 = type(v2)
    if (t1 ~= t2) then
        error('got different values: "' .. toPrettyPrint(v1) ..'" : "'..  toPrettyPrint(v2) .. '"')
    end

    if (v1 ~= v2) then
        if (t1 == "table") then
            -- recurse into both tables
            for k, v in pairs(v1) do
                
                assertEqual(v1[k], v2[k])
            end
            for k, v in pairs(v2) do
                if v1[k] == nil and v2[k] ~= nil then
                    error('v1 is missing value for key '.. k)
                end
            end
        else
            print(v1)
            print(v2)
            error('got different values: "' .. toPrettyPrint(v1) ..'" : "'..  toPrettyPrint(v2) .. '"')
        end
    end    
end

function fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function doubleToBytes(n)
    return string.pack("d", n)
end

-- Take a signed integer and converts it to bytes
-- Lua uses doubles, so this only works nice for numbers < 2^53
-- truncates the remainder if it is not a number
function intToBytes(n) 
    if (math.type(n) == 'nil') then
        error("n is not a number: " .. n)
    elseif (math.type(n) == 'float') then
        n = math.floor(n)
    end

    return string.pack("i", n)
end

function gen_uuid()
    local ret = ""
    for i = 1,16 do
        -- TODO: better randomness source?
        local byte = math.random(256) - 1
        ret = ret .. string.char(byte)
    end
    return ret
end


function tokenize(str)
    -- TODO handle escaped quotes
    local res = {}
    local quoted_str = nil
    for sub_str in string.gmatch(str, '[^ ]*') do
        if string.match(sub_str, "^\"") then
            quoted_str = sub_str
        elseif quoted_str ~= nil then
            quoted_str = quoted_str .. " " .. sub_str
        else
            table.insert(res, sub_str)
        end

        if string.match(sub_str, "\"$") then
            table.insert(res, quoted_str)
            quoted_str = nil
        end
        
    end
    return res
end

function parseArgs()
    local options = {
        name = "repl_test",
        in_memory = false,
        reset = false,
        port = 25600
    }
   
    if #arg > 0 then
        local skip_one = false
        for i = 1,#arg do
            if skip_one == true then
                skip_one = false
            else
                local a = arg[i]
                logDebug(a)
                if a == "--memory" then
                    options.in_memory = true
                elseif  a == "--reset" then
                    options.reset = true
                elseif a == "--name" then
                    i = i + 1
                    if arg[i] == nil then
                        error("Missing name following --name")
                    end
                    options.name = arg[i]
                    skip_one = true
                elseif a == "--port" then
                    i = i + 1
                    if arg[i] == nil then
                        error("Missing port number following --port")
                    end
                    options.port = tonumber(arg[i])
                    skip_one = true
                
                end
            end
        end
    end
    return options
end
