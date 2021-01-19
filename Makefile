##########################################################################################
# Platform auto detect
##########################################################################################
SUPPORTED_PLATFORMS := linux darwin
PLATFORMNAME        ?= $(shell echo $(shell uname) | tr "[:upper:]" "[:lower:]")
$(if $(findstring $(PLATFORMNAME),$(SUPPORTED_PLATFORMS)),,$(error "Unsupported os, must be one of '$(SUPPORTED_PLATFORMS)'"))

##########################################################################################
# Compile commands
##########################################################################################
.PHONY: all darwin macosx test clean help

all: $(PLATFORMNAME)

linux:
	@echo "========== make skynet start =========="
	cd ./skynet;make cleanall;make linux
	@echo "========== make skynet end =========="

	@echo "\n\n\n========== make cjson start =========="
	cd ./game/lib/json;make linux
	@echo "========== make cjson end =========="

	@echo "\n\n\n========== make zlib start =========="
	cd ./game/lib/lua-zlib;make linux
	@echo "========== make zlib end =========="

	@echo "\n\n\n========== make zset start =========="
	cd ./game/lib/lua-zset;make linux
	@echo "========== make zset end =========="

	@echo "\n\n\n========== make timer start =========="
	cd ./game/lib/lua-timer;make linux
	@echo "========== make timer end =========="

macosx: darwin

darwin:
	@echo "========== make skynet start =========="
	cd ./skynet;make cleanall;make macosx
	@echo "========== make skynet end =========="

	@echo "\n\n\n========== make cjson start =========="
	cd ./game/lib/json;make macosx
	@echo "========== make cjson end =========="

	@echo "\n\n\n========== make zlib start =========="
	cd ./game/lib/lua-zlib;make macosx
	@echo "========== make zlib end =========="

	@echo "\n\n\n========== make zset start =========="
	cd ./game/lib/lua-zset;make macosx
	@echo "========== make zset end =========="

	@echo "\n\n\n========== make timer start =========="
	cd ./game/lib/lua-timer;make macosx
	@echo "========== make timer end =========="


test:
	@echo "========== test cjson start =========="
	cd ./game/lib/json;lua test.lua
	@echo "========== test cjson end =========="

	@echo "\n\n\n========== test zlib start =========="
	cd ./game/lib/lua-zlib;lua test.lua
	@echo "========== test zlib end =========="

	@echo "\n\n\n========== test zset start =========="
	cd ./game/lib/lua-zset;lua test.lua
	@echo "========== test zset end =========="

clean:
	@echo "========== clean skynet start =========="
	cd ./skynet;make cleanall
	@echo "========== clean skynet end =========="

	@echo "\n\n\n========== clean cjson start =========="
	cd ./game/lib/json;make clean
	@echo "========== clean cjson end =========="

	@echo "\n\n\n========== clean zlib start =========="
	cd ./game/lib/lua-zlib;make clean
	@echo "========== clean zlib end =========="

	@echo "\n\n\n========== clean zset start =========="
	cd ./game/lib/lua-zset;make clean
	@echo "========== clean zset end =========="

	@echo "\n\n\n========== clean timer start =========="
	cd ./game/lib/lua-timer;make clean
	@echo "========== clean timer end =========="

help:
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * test"
	@echo "  * clean"
