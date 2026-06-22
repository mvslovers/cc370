# as370 - host-native MVS assembler (standalone convenience build;
# the top-level Makefile builds all tools together)
CC      ?= cc
CFLAGS  ?= -g -O0 -Wall -Wextra -std=gnu99
PROG     = as370

$(PROG): src/as370.c include/opc_table.h
	$(CC) $(CFLAGS) -Iinclude -o $@ src/as370.c

.PHONY: test clean
test: $(PROG)
	@./tests/run.sh

clean:
	rm -f $(PROG)
