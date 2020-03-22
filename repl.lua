require('./kv')
require('./logging')

function repl()
    local options = parseArgs()
    local store = KV_Store:new(options)
    io.write('> ')
    for line in io.lines() do
        if line == 'EXIT' then
            break
        elseif line == 'RESET' then
            options.reset = true
            store = KV_Store:new(options)
        else
            local res = store:exec(line)
            print(res)
        end
        io.write('> ')
    end
    store:close()

end

function parseArgs()
    local options = {
        name = "repl_test",
        in_memory = false,
        reset = false
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
                end
            end
        end
    end
    return options
end

repl()
