

.PHONY: test
test:
	lua test.lua
	cat test_scripts/test_populate.txt | lua repl.lua --memory

.PHONY: mc-copy
mc-copy:
	# hard coded path for testing on my machine
	# have to exit / reload world to see new files
	cp -r ./* ~/.minecraft/saves/DS/opencomputers/bd1e1950-b299-4c32-81ef-82f513585deb/home/kvstore/