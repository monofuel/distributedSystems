
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
    print(level, "|", str)
end
