# Distributed Systems

- requires lua 5.3
- requires luasocket (installed with luarocks)

  - Dockerfile & docker-compose.yml for running included

- simple KV store intended for [Open Computers Minecraft Mod](https://ocdoc.cil.li/tutorial:oc1_basic_computer)
  - Networking not working yet for Open Computers
    - currently only supports luasockets on x86
    - need to add support for the network on Open Computers
  - replication with syncronous leader & follower

* TODO

  - Finish implementing WAL recovery after crash

  - function argument checking?

    - maybe async leader & follower?

* stretch goals
  - partitioning
  - transactions?
    - partitioning with transactions?
  - lua coroutines? io multiplexing?
  - cache proxies? orchestration?

# Manual Testing

- `docker-compose up leader follower-1 follower-2` to start the servers
- `docker-compose run repl` to open up a REPL for the leader
- `docker-compose run repl-follower` to open up a REPL for follower-1

# Notes

http://lua-users.org/files/wiki_insecure/users/thomasl/luarefv51single.pdf

- https://www.lua.org/manual/5.3/manual.html#6.4.2
  - string.pack and string.unpack are AWESOME

https://ocdoc.cil.li/component:modem

- open computers needs to be set to 5.3!
  - you can change the architecture by holding a CPU in hand and shift right clicking
  - or you can change your open computers config to default to 5.3

- open computers defaults to `filesystem.bufferChanges=true` which means data commited to disk in Minecraft may not be commited on the real physical drive.

# Naming

- snake_case for variables/functions
- UPPER_CASE for constants.
- PascalCase for classes.
- \_\_snake_case for private/hidden variables.
