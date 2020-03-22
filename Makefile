

.PHONY: test
test:
	lua test.lua
	cat test_scripts/test_populate.txt | lua repl.lua --memory
