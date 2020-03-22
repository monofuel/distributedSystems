# Distributed Systems

- simple KV
- store

- TODO

  - Finish WAL
  - allow hexidecimal for passing data via repl

    - not great, but it's flexible and means I don't have to parse objects

  - argument checking
  - replication
  - partitioning

  - transactions?
    - partitioning with transactions?

- stretch goals
  - lua coroutines? io multiplexing?
  - cache proxies? orchestration?

# Notes

http://lua-users.org/files/wiki_insecure/users/thomasl/luarefv51single.pdf

- https://www.lua.org/manual/5.3/manual.html#6.4.2
  - string.pack and string.unpack are AWESOME

# Naming

- snake_case for variables/functions
- UPPER_CASE for constants.
- PascalCase for classes.
- \_\_snake_case for private/hidden variables.
