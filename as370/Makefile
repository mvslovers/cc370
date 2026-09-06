# as370 - host-native MVS assembler (standalone convenience build;
# the top-level Makefile builds all tools together)
CC      ?= cc
CFLAGS  ?= -g -O0 -Wall -Wextra -std=gnu99
PROG     = as370

COMMON   = ../common/src/mvs370.c
COMMONH  = ../common/include/mvs370.h

$(PROG): src/as370.c include/opc_table.h $(COMMON) $(COMMONH)
	$(CC) $(CFLAGS) -Iinclude -I../common/include -o $@ src/as370.c $(COMMON)

.PHONY: test clean
test: $(PROG)
	@./tests/run.sh

clean:
	rm -f $(PROG)
