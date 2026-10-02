# as370 - host-native MVS assembler (standalone convenience build;
# the top-level Makefile builds all tools together)
CC      ?= cc
CFLAGS  ?= -g -O0 -Wall -Wextra -std=gnu99
PROG     = as370

COMMON   = ../common/src/mvs370.c ../common/src/obj370.c
COMMONH  = ../common/include/mvs370.h
VERHDR   = ../common/include/cc370-version.h

$(PROG): src/as370.c include/opc_table.h $(COMMON) $(COMMONH) $(VERHDR)
	$(CC) $(CFLAGS) -Iinclude -I../common/include -o $@ src/as370.c $(COMMON)

.PHONY: test clean FORCE
# rewritten only when the version or the commit changes (../common/mkversion.sh)
$(VERHDR): FORCE
	@sh ../common/mkversion.sh $@
FORCE:

test: $(PROG)
	@./tests/run.sh

clean:
	rm -f $(PROG)
