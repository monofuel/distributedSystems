require('./util')

Net_Service = {}

function Net_Service:new()
    local service = setmetatable({}, { __index = Net_Service })
    service.__coroutines = {}
    return service
end

function Net_Service:tick()
    for _, v in ipairs(self.__coroutines) do
        routineResume(v)
    end
end

if isOC() then
    local component = require("component")
    local event = require("event")

    function Net_Service:leaderListen(port)
        assert(m.open(port))

        local routine = coroutine.create(function()
            while 1 do
    
                -- NB not sure what a1, a2 and a3 are
                 -- TODO should filter on port
                local a1, a2, from, port, a3, message = event.pull(0, "modem_message")
                if not a1 then
                    
                    print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
                    print(a1, a2, a3)
                else
                    print('a1')
                    print(a1)
                end

                coroutine.yield()
            end
        end)

        table.insert(self.__coroutines, routine)
    end

    function Net_Service:replListen(port)
        assert(m.open(port))

        local routine = coroutine.create(function()
            while 1 do
    
                -- NB not sure what a1, a2 and a3 are
                -- TODO should filter on port
                local a1, a2, from, port, a3, message = event.pull(0, "modem_message")
                if not a1 then
                    
                    print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
                    print(a1, a2, a3)
                else
                    print('a1')
                    print(a1)
                end

                coroutine.yield()
            end
        end)

        table.insert(self.__coroutines, routine)
    end

----------------------------------------------------------------------------------------------
else -- x86 luaSockets

    local socket = require('socket')

    function Net_Service:leaderListen(port)
        local leader_server = assert(socket.bind("*", port))
        -- TODO should this be 0?
        leader_server:settimeout(1)

        local sockets = {
            leader_server
        }
        local db_clients = {}
        self.__leader_sockets = sockets
        self.__db_clients = db_clients

        local routine = coroutine.create(function()
            while 1 do

                local ready = socket.select(sockets, nil, 0) 

                for _, sock in ipairs(ready) do
                    if sock == leader_server then
                        local client, err = sock:accept()
                       
                        if err then
                            logErr('error accepting follower: ' .. err)
                        else
                            logInfo("db client connected!")
                     
                            table.insert(db_clients, client)
                            table.insert(sockets, client)
                        end
                    else
                        -- TODO handle msgs from followers
                    end
                end
                coroutine.yield()
            end
        end)
        table.insert(self.__coroutines, routine)

    end

    -- TODO should define a better abstraction between net and kv store
    -- probably should pass callbacks
    function Net_Service:replListen(port, store)
        local repl_server  = assert(socket.bind("*", port))
        -- TODO should this be 0?
        repl_server:settimeout(1)

        local sockets = {
            repl_server
        }
        self.__repl_sockets = sockets
        
        local repl_clients = {}
        self.__repl_clients = repl_clients

        local routine = coroutine.create(function()
            while 1 do

                local ready = socket.select(sockets, nil, 0) 

                for _, sock in ipairs(ready) do
                    if sock == repl_server then
                        local client, err = sock:accept()
    
                        if err then
                            logErr('error accepting repl client: ' .. err)
                        else
                            logInfo("repl client connected!")
    
                            table.insert(repl_clients, client)
                            table.insert(sockets, client)
                        end
                    else
                        -- REPL clients
                local line, err = sock:receive('*l')
                
                if err then
                    if err == 'closed' then
                        logErr('client closed')
                        table.remove(repl_clients, sock)
                    else
                        logErr('error receiving from repl client: ' .. err)
                    end
                else
                    logInfo('client request: ' .. line)
                    local res = store:exec(line)
                    sock:send(tostring(res) .. '\n')
                    
                end
                    end
                end
                coroutine.yield()
            end
        end)
        table.insert(self.__coroutines, routine)
    end

    function Net_Service:countFollowers()
        if self.__db_clients then
            return #self.__db_clients
        else
            return 0
        end
    end

    function Net_Service:broadcastFollowers(buf)
        local clients = self.__db_clients
        if not clients then
            return
        end
        -- syncronously send WAL events to clients
        -- TODO async followers?
        for _, sock in ipairs(clients) do
            -- first send size of buf as an int, followed by a newline
            -- hacky way to send arbitrary binary data with luasockets
            sock:send(intToBytes(#buf) .. '\n')
            sock:send(buf)
        end
    end

    -- TODO should define a better abstraction between net and kv store
    -- probably should pass callbacks
    function Net_Service:follow(leaderHost, leaderPort, store)
        local client, err = socket.connect(leaderHost, leaderPort)
        if err then
            error('failed to connect to leader: ' .. err)
        end
        logInfo('connected to leader!')
        self.__client = client
        local sockets = { client }
        self.__follower_sockets = sockets
        local routine = coroutine.create(function()
            while 1 do
                
                local ready = socket.select(sockets, nil, 0) 

                for _, sock in ipairs(ready) do
                    if sock == client then
                        -- TODO better error handling here
                        local line, error = client:receive('*l')
                        if error then
                            error('client receive error: ' .. error)
                        end
                        local count = string.unpack("i", line)
                        local buf, error = client:receive(count)
                        if error then
                            error('client receive error: ' .. error)
                        end

                        -- commit to local WAL
                        if not store.__in_memory then
                            store.wal_file:write(buf)
                            store.wal_file:flush()
                        end
                        
                        local wal_event = decode(buf, WAL_Schema)
                        local kind = getNameForWALKind(wal_event.kind)
                        logInfo("follower received event ID: " .. wal_event.ID .. ' kind: ' .. wal_event.kind)
                        local schema = WAL_Schemas[kind]
                        local value = decode(wal_event.bytes, schema)

                        -- mutate internal state
                        store:handleWAL(kind, value)
                        logInfo('handled event ID: ' .. wal_event.ID)
                        
                    else
                        logErr('unknown socket')
                    end
                end

                -- local line, err = client:receive()
                -- if not err then 
                
                -- end
                -- client:close()
                coroutine.yield()
            end
        end)
        table.insert(self.__coroutines, routine)
    end

    function Net_Service:close()
        if self.__leader_sockets then
            for _, sock in ipairs(self.__leader_sockets) do
                sock:close()
            end
        end

        if self.__repl_sockets then
            for _, sock in ipairs(self.__repl_sockets) do
                sock:close()
            end
        end

        if self.__follower_sockets then
            for _, sock in ipairs(self.__follower_sockets) do
                sock:close()
            end
        end
    end
end


return Net_Service