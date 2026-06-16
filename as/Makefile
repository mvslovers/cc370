# as370 - host-native MVS assembler (WP-2 skeleton)
CC      ?= cc
CFLAGS  ?= -g -O0 -Wall -Wextra -std=gnu99
PROG     = as370

$(PROG): as370.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: test clean
test: $(PROG)
	./$(PROG) tests/sample1.s

clean:
	rm -f $(PROG)
