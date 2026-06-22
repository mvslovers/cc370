# cc370 -- host-native MVS cross-toolchain build + install.
#
# One driver (cc370) plus three standalone tools (as370 / ld370 / ar370).
# Clean cc370-branded layout under $(PREFIX): everything for the target lives in
# one cc370/ tree; only the user-facing binaries sit on PATH.  (The
# i370-ibm-mvspdp triple is an internal config.sub alias; nothing here carries it.)
#
#   bin/cc370                      the driver (the only "driver")
#   bin/{as370,ld370,ar370}        symlinks -> ../cc370/bin/* (PATH access)
#   libexec/cc370/1.0.0/cc1        the compiler proper (driver-private)
#   libexec/cc370/1.0.0/{as,ld,ar} symlinks beside cc1; the driver's tooldir,
#                                  where it looks up as/ld/ar by short name
#   cc370/bin/{as370,ld370,ar370}  the real tool binaries
#   cc370/{include,lib,macros}     the libc370 sysroot (headers, libc.a, crt*.o,
#                                  + macros; as370 finds them via <exedir>/../macros)
#   lib/cc370/1.0.0/               GCC's libsubdir: empty (we ship no libgcc) but
#                                  REQUIRED -- the driver locates the cc370/ sysroot
#                                  (headers AND -lc) via a path relative to it
#
#   make / make all build the whole toolchain (cc370 + as370/ld370/ar370)
#   make tools      only as370 / ld370 / ar370   [fast]
#   make gcc        configure + build the driver (cc370) and cc1   [slow]
#   make install    install everything into $(PREFIX)
#   make clean / uninstall / help

PREFIX  ?= $(HOME)/.local
# cc370 is the toolchain's target name (config.sub aliases it to the real
# i370-ibm-mvspdp backend); it is what shows up in the install paths.
TRIPLE  ?= cc370
GCCVER  ?= 1.0.0
HOSTCC  ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -Werror

BINDIR  := $(PREFIX)/bin
TGTBIN  := $(PREFIX)/$(TRIPLE)/bin
LIBEXEC := $(PREFIX)/libexec/$(TRIPLE)/$(GCCVER)
MANDIR  := $(PREFIX)/share/man/man1

TOOLS   := as370/as370 ld370/ld370 ar370/ar370
# man pages: one .pod per tool -> pod2man -> .1 (the same path GCC uses)
MANPODS := $(wildcard man/*.pod)
MAN1    := $(MANPODS:.pod=.1)

# --- GCC (driver + cc1) build, out-of-tree in build/ ----------------------
# Old K&R-ish 3.4.6 sources: tell the modern host compiler not to error on them.
GCC_CF  := -g -O0 -fcommon -std=gnu89 -Wno-implicit-int \
           -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error \
           -Wno-return-type -Wno-deprecated-non-prototype
BUILD   := build
DRIVER  := $(BUILD)/gcc/xgcc
CC1     := $(BUILD)/gcc/cc1

.PHONY: all tools gcc man install install-tools install-gcc install-man clean uninstall help
# `make` / `make all` builds the whole toolchain (cc370 + as370/ld370/ar370 + man).
# `make tools` is the fast path that builds only the three standalone tools.
all: tools gcc man

# --- standalone tools (normal single-file C binaries) ---------------------
tools: $(TOOLS)
as370/as370: as370/src/as370.c as370/include/opc_table.h
	$(HOSTCC) $(CFLAGS) -Ias370/include -o $@ $<
ld370/ld370: ld370/src/ld370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<
ar370/ar370: ar370/src/ar370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<

# --- man pages (one .pod per tool -> pod2man -> .1) -----------------------
man: $(MAN1)
man/%.1: man/%.pod
	pod2man --section=1 --center="cc370 toolchain" --release="cc370 $(GCCVER)" $< > $@

# --- driver + cc1 (GCC autotools) -----------------------------------------
$(BUILD)/config.status:
	mkdir -p $(BUILD)
	cd $(BUILD) && CFLAGS="$(GCC_CF)" CFLAGS_FOR_BUILD="$(GCC_CF)" ../cc370/configure \
	    --target=$(TRIPLE) --enable-languages=c --disable-threads --disable-nls \
	    --disable-shared --without-headers \
	    --with-gcc-version-trigger=../cc370/gcc/version.c

gcc: $(BUILD)/config.status
	$(MAKE) -C $(BUILD) all-gcc CFLAGS="$(GCC_CF)" CFLAGS_FOR_BUILD="$(GCC_CF)"

# --- install --------------------------------------------------------------
install: install-tools install-gcc install-man

install-tools: tools
	mkdir -p $(TGTBIN) $(BINDIR) $(LIBEXEC)
	install -m 755 as370/as370 $(TGTBIN)/as370    # the real tools live in the sysroot bin
	install -m 755 ld370/ld370 $(TGTBIN)/ld370
	install -m 755 ar370/ar370 $(TGTBIN)/ar370
	ln -sf ../$(TRIPLE)/bin/as370 $(BINDIR)/as370       # PATH access (relative -> relocatable)
	ln -sf ../$(TRIPLE)/bin/ld370 $(BINDIR)/ld370
	ln -sf ../$(TRIPLE)/bin/ar370 $(BINDIR)/ar370
	ln -sf ../../../$(TRIPLE)/bin/as370 $(LIBEXEC)/as   # the driver's tooldir, beside cc1:
	ln -sf ../../../$(TRIPLE)/bin/ld370 $(LIBEXEC)/ld   # it looks up as/ld/ar here by short
	ln -sf ../../../$(TRIPLE)/bin/ar370 $(LIBEXEC)/ar   # name (no empty lib/ dir needed)
	@echo "installed tools -> $(TGTBIN) (PATH links $(BINDIR), tooldir links $(LIBEXEC))"

# install cc1 + the driver renamed to cc370 (needs a prior `make gcc`)
install-gcc:
	@test -x $(DRIVER) -a -x $(CC1) || { \
	  echo "no driver/cc1 in $(BUILD) -- run 'make gcc' first (slow)"; exit 1; }
	mkdir -p $(LIBEXEC) $(BINDIR)
	install -m 755 $(CC1) $(LIBEXEC)/cc1
	install -m 755 $(DRIVER) $(BINDIR)/cc370
	# GCC's libsubdir. Empty (we ship no libgcc), but it MUST exist: the driver
	# locates the whole $(TRIPLE)/ sysroot -- both <stdio.h> and -lc -- via a path
	# relative to it ($(PREFIX)/lib/$(TRIPLE)/$(GCCVER)/../../../$(TRIPLE)/...).
	# Without it: "cannot find -lc" and no headers.
	mkdir -p $(PREFIX)/lib/$(TRIPLE)/$(GCCVER)
	@echo "installed cc370 -> $(BINDIR)/cc370 ; cc1 -> $(LIBEXEC)/cc1"

install-man: man
	mkdir -p $(MANDIR)
	install -m 644 $(MAN1) $(MANDIR)/
	@echo "installed man pages -> $(MANDIR)"

clean:
	rm -f $(TOOLS) $(MAN1)

uninstall:
	rm -f $(BINDIR)/cc370 $(BINDIR)/as370 $(BINDIR)/ld370 $(BINDIR)/ar370 \
	      $(TGTBIN)/as370 $(TGTBIN)/ld370 $(TGTBIN)/ar370 \
	      $(LIBEXEC)/as $(LIBEXEC)/ld $(LIBEXEC)/ar $(LIBEXEC)/cc1 \
	      $(MANDIR)/cc370.1 $(MANDIR)/as370.1 $(MANDIR)/ld370.1 $(MANDIR)/ar370.1

help:
	@sed -n '1,30p' $(firstword $(MAKEFILE_LIST))
