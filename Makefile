# cc370 -- host-native MVS cross-toolchain build + install.
#
# One driver (cc370) plus four standalone tools (as370 / ld370 / ar370 / file370).
# file370 is the read-only inspector (`file`/objdump for the toolchain formats);
# it is not invoked by the driver, so it gets a PATH link but no tooldir link.
# Clean cc370-branded layout under $(PREFIX): everything for the target lives in
# one cc370/ tree; only the user-facing binaries sit on PATH.  (The
# i370-ibm-mvspdp triple is an internal config.sub alias; nothing here carries it.)
#
#   bin/cc370                      the driver (the only "driver")
#   bin/{as370,ld370,ar370,file370} symlinks -> ../cc370/bin/* (PATH access)
#   libexec/cc370/1.0.0/cc1        the compiler proper (driver-private)
#   libexec/cc370/1.0.0/{as,ld,ar} symlinks beside cc1; the driver's tooldir,
#                                  where it looks up as/ld/ar by short name
#   cc370/bin/{as370,ld370,ar370,file370}  the real tool binaries
#   cc370/{include,lib,macros}     the libc370 sysroot (headers, libc.a, crt*.o,
#                                  + macros; as370 finds them via <exedir>/../macros)
#   lib/cc370/1.0.0/               EMPTY but REQUIRED -- this is GCC's libsubdir
#                                  (would hold libgcc; we ship none, so it is empty).
#                                  The compiler driver locates the cc370/ sysroot --
#                                  both <stdio.h> and -lc -- via a path relative to
#                                  it; remove it and the link fails ("cannot find
#                                  -lc"). Created by install-compiler. Leave it be.
#
#   make / make all build the whole toolchain (cc370 + as370/ld370/ar370/file370 + man)
#   make tools      only as370 / ld370 / ar370 / file370   [fast]
#   make compiler   configure + build the driver (cc370) and cc1   [slow]
#   make install    build (if needed) + install everything into $(PREFIX)
#   make clean / uninstall / help

PREFIX  ?= $(HOME)/.local
# cc370 is the toolchain's target name (config.sub aliases it to the real
# i370-ibm-mvspdp backend); it is what shows up in the install paths.
TRIPLE  ?= cc370
VERSION ?= 1.0.0
HOSTCC  ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -Werror

BINDIR  := $(PREFIX)/bin
TGTBIN  := $(PREFIX)/$(TRIPLE)/bin
LIBEXEC := $(PREFIX)/libexec/$(TRIPLE)/$(VERSION)
MANDIR  := $(PREFIX)/share/man/man1

TOOLS   := as370/as370 ld370/ld370 ar370/ar370 file370/file370
# man pages: one .pod per tool -> pod2man -> .1
MANPODS := $(wildcard man/*.pod)
MAN1    := $(MANPODS:.pod=.1)

# --- compiler (cc370 driver + cc1) build, out-of-tree in build/ -----------
# The compiler is a GCC 3.4.6 fork built as old K&R-ish C on a modern host:
# the -Wno-* downgrade gcc-14's default *errors* (implicit-int etc.) so it
# compiles; -w silences the (harmless) warning noise from the upstream sources
# we don't modify. Errors still show. -w rides in CFLAGS so it reaches every
# sub-build (the build's own WARN_CFLAGS can't be overridden from the top).
COMPILER_CF := -g -O0 -fcommon -std=gnu89 -w -Wno-implicit-int \
               -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error \
               -Wno-return-type -Wno-deprecated-non-prototype
BUILD   := build
DRIVER  := $(BUILD)/gcc/xgcc
CC1     := $(BUILD)/gcc/cc1

.PHONY: all tools compiler man install install-tools install-compiler install-man clean uninstall help
# `make` / `make all` builds the whole toolchain (cc370 + as370/ld370/ar370 + man).
# `make tools` is the fast path that builds only the three standalone tools.
all: tools compiler man

# --- standalone tools (normal single-file C binaries) ---------------------
tools: $(TOOLS)
as370/as370: as370/src/as370.c as370/include/opc_table.h
	$(HOSTCC) $(CFLAGS) -Ias370/include -o $@ $<
ld370/ld370: ld370/src/ld370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<
ar370/ar370: ar370/src/ar370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<
file370/file370: file370/src/file370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<

# --- man pages (one .pod per tool -> pod2man -> .1) -----------------------
man: $(MAN1)
man/%.1: man/%.pod
	pod2man --section=1 --center="cc370 toolchain" --release="cc370 $(VERSION)" $< > $@

# --- compiler: the cc370 driver + cc1 (a GCC 3.4.6 autotools build) -------
$(BUILD)/config.status:
	mkdir -p $(BUILD)
	cd $(BUILD) && CFLAGS="$(COMPILER_CF)" CFLAGS_FOR_BUILD="$(COMPILER_CF)" ../cc370/configure \
	    --target=$(TRIPLE) --enable-languages=c --disable-threads --disable-nls \
	    --disable-shared --without-headers \
	    --with-gcc-version-trigger=../cc370/gcc/version.c

compiler: $(BUILD)/config.status
	$(MAKE) -C $(BUILD) all-gcc CFLAGS="$(COMPILER_CF)" CFLAGS_FOR_BUILD="$(COMPILER_CF)"

# --- install --------------------------------------------------------------
install: install-tools install-compiler install-man

# Real tool binaries -> $(TGTBIN) (the sysroot bin); $(BINDIR) gets PATH symlinks
# and $(LIBEXEC) gets the driver's tooldir symlinks (both relative -> relocatable).
install-tools: tools
	@mkdir -p $(TGTBIN) $(BINDIR) $(LIBEXEC)
	@install -m 755 as370/as370 $(TGTBIN)/as370
	@install -m 755 ld370/ld370 $(TGTBIN)/ld370
	@install -m 755 ar370/ar370 $(TGTBIN)/ar370
	@install -m 755 file370/file370 $(TGTBIN)/file370
	@ln -sf ../$(TRIPLE)/bin/as370 $(BINDIR)/as370
	@ln -sf ../$(TRIPLE)/bin/ld370 $(BINDIR)/ld370
	@ln -sf ../$(TRIPLE)/bin/ar370 $(BINDIR)/ar370
	@ln -sf ../$(TRIPLE)/bin/file370 $(BINDIR)/file370
	@ln -sf ../../../$(TRIPLE)/bin/as370 $(LIBEXEC)/as
	@ln -sf ../../../$(TRIPLE)/bin/ld370 $(LIBEXEC)/ld
	@ln -sf ../../../$(TRIPLE)/bin/ar370 $(LIBEXEC)/ar
	@echo "installed tools -> $(TGTBIN) (PATH links $(BINDIR), tooldir links $(LIBEXEC))"

# cc1 (driver-private) + the driver as cc370.  Depends on `compiler`, so
# `make install` builds it when needed (no more half-install).  Also creates the
# empty libsubdir $(PREFIX)/lib/$(TRIPLE)/$(VERSION) -- see the note at the top.
install-compiler: compiler
	@mkdir -p $(LIBEXEC) $(BINDIR) $(PREFIX)/lib/$(TRIPLE)/$(VERSION)
	@install -m 755 $(CC1) $(LIBEXEC)/cc1
	@install -m 755 $(DRIVER) $(BINDIR)/cc370
	@echo "installed cc370 -> $(BINDIR)/cc370 ; cc1 -> $(LIBEXEC)/cc1"

install-man: man
	@mkdir -p $(MANDIR)
	@install -m 644 $(MAN1) $(MANDIR)/
	@echo "installed man pages -> $(MANDIR)"

clean:
	rm -rf $(BUILD)
	rm -f $(TOOLS) $(MAN1)

uninstall:
	rm -f $(BINDIR)/cc370 $(BINDIR)/as370 $(BINDIR)/ld370 $(BINDIR)/ar370 $(BINDIR)/file370 \
	      $(TGTBIN)/as370 $(TGTBIN)/ld370 $(TGTBIN)/ar370 $(TGTBIN)/file370 \
	      $(LIBEXEC)/as $(LIBEXEC)/ld $(LIBEXEC)/ar $(LIBEXEC)/cc1 \
	      $(MANDIR)/cc370.1 $(MANDIR)/as370.1 $(MANDIR)/ld370.1 $(MANDIR)/ar370.1 $(MANDIR)/file370.1

help:
	@sed -n '1,30p' $(firstword $(MAKEFILE_LIST))
