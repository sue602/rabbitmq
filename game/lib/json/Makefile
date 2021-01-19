TARGET =            cjson.so
PREFIX =            /usr/local
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG
CJSON_CFLAGS =      -fpic
SKYNET_INC = ../../../skynet/skynet-src
LUA_INCLUDE_DIR = ../../../skynet/3rd/lua
LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

FPCONV_OBJS =       fpconv.o

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -I$(SKYNET_INC) $(CJSON_CFLAGS)
OBJS =              lua_cjson.o strbuf.o $(FPCONV_OBJS)

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so

