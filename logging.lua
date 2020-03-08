require('./config')


function debug(str)
    log('DEBUG', str)
end

function info(str)
    log('INFO', str)
end

function err(str)
    log('ERR', str)
end

function warn(str)
    log('WARN', str)
end

-- levels
-- ERR WARN INFO DEBUG
function log(level, str)
    -- TODO use LOG_LEVEL
    print(level, "|", str)
end

function toPrettyPrint(v, preStr)
    if preStr == nil then
        preStr = ''
    else
        
    end
    --  "nil" | "number" | "string" | "boolean" | "table" | "function" | "thread" | "userdata"
    local t = type(v)
    if t == 'nil' or t == 'number' or t == 'string' or t == 'boolean' then
        return preStr .. tostring(v)
    elseif t == 'table' then
        local str = preStr .. '{'
        for k2, v2 in pairs(v) do
            str = str .. '\n' .. preStr .. k2 .. ' = '
            str = str .. toPrettyPrint(v2, preStr .. '  ')
        end
        return str .. '\n' .. preStr ..  '}'
    end
end
