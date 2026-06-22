# cc370 -- host-native MVS cross-toolchain build + install.
#
# One driver (cc370) plus three standalone tools (as370 / ld370 / ar370).
# Matches a normal cross-toolchain layout under $(PREFIX):
#
#   bin/cc370                      the GCC 3.4.6 driver (the only "driver")
#   bin/{as370,ld370,ar370}        PATH symlinks -> the real tools below
#   libexec/gcc/<triple>/<ver>/cc1 the compiler proper (driver-private)
#   <triple>/bin/{as370,ld370,ar370} + {as,ld,ar}   the tools (driver finds as/ld here)
#   <triple>/{include,lib,macros}  the crent libc sysroot (installed by crent370/sdk)
#
# The tools live in <triple>/bin so as370's built-in default macro path
# (<exedir>/../macros) resolves to the sysroot; the bin/ symlinks resolve back
# to the same real path, so `as370` on PATH still finds the macros.
#
#   make            build the tools
#   make tools      as370 / ld370 / ar370
#   make gcc        configure + build the driver (cc370) and cc1   [slow]
#   make install    install tools (+ gcc if built) into $(PREFIX)
#   make clean / uninstall / help

PREFIX  ?= $(HOME)/.local
TRIPLE  ?= i370-ibm-mvspdp
GCCVER  ?= 3.4.6
HOSTCC  ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -Werror

BINDIR  := $(PREFIX)/bin
TGTBIN  := $(PREFIX)/$(TRIPLE)/bin
LIBEXEC := $(PREFIX)/libexec/gcc/$(TRIPLE)/$(GCCVER)

TOOLS   := as370/as370 ld370/ld370 ar370/ar370

# --- GCC (driver + cc1) build, out-of-tree in build/ ----------------------
# Old K&R-ish 3.4.6 sources: tell the modern host compiler not to error on them.
GCC_CF  := -g -O0 -fcommon -std=gnu89 -Wno-implicit-int \
           -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error \
           -Wno-return-type -Wno-deprecated-non-prototype
BUILD   := build
DRIVER  := $(BUILD)/gcc/xgcc
CC1     := $(BUILD)/gcc/cc1

.PHONY: all tools gcc install install-tools install-gcc clean uninstall help
all: tools

# --- standalone tools (normal single-file C binaries) ---------------------
tools: $(TOOLS)
as370/as370: as370/src/as370.c as370/include/opc_table.h
	$(HOSTCC) $(CFLAGS) -Ias370/include -o $@ $<
ld370/ld370: ld370/src/ld370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<
ar370/ar370: ar370/src/ar370.c
	$(HOSTCC) $(CFLAGS) -o $@ $<

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
install: install-tools install-gcc

install-tools: tools
	mkdir -p $(TGTBIN) $(BINDIR)
	install -m 755 as370/as370 $(TGTBIN)/as370
	install -m 755 ld370/ld370 $(TGTBIN)/ld370
	install -m 755 ar370/ar370 $(TGTBIN)/ar370
	ln -sf as370 $(TGTBIN)/as          # names the cc370 driver invokes
	ln -sf ld370 $(TGTBIN)/ld
	ln -sf ar370 $(TGTBIN)/ar
	ln -sf ../$(TRIPLE)/bin/as370 $(BINDIR)/as370    # PATH access (symlink resolves
	ln -sf ../$(TRIPLE)/bin/ld370 $(BINDIR)/ld370    # back to the real target-bin
	ln -sf ../$(TRIPLE)/bin/ar370 $(BINDIR)/ar370    # binary -> macro path still works)
	rm -f $(LIBEXEC)/as                # drop the obsolete stopgap as-wrapper
	@echo "installed tools -> $(TGTBIN) (+ PATH symlinks in $(BINDIR))"

# install cc1 + the driver renamed to cc370 (needs a prior `make gcc`)
install-gcc:
	@test -x $(DRIVER) -a -x $(CC1) || { \
	  echo "no driver/cc1 in $(BUILD) -- run 'make gcc' first (slow)"; exit 1; }
	mkdir -p $(LIBEXEC) $(BINDIR)
	install -m 755 $(CC1) $(LIBEXEC)/cc1
	install -m 755 $(DRIVER) $(BINDIR)/cc370
	@echo "installed cc370 -> $(BINDIR)/cc370 ; cc1 -> $(LIBEXEC)/cc1"

clean:
	rm -f $(TOOLS)

uninstall:
	rm -f $(BINDIR)/cc370 $(BINDIR)/as370 $(BINDIR)/ld370 $(BINDIR)/ar370 \
	      $(TGTBIN)/as370 $(TGTBIN)/ld370 $(TGTBIN)/ar370 \
	      $(TGTBIN)/as $(TGTBIN)/ld $(TGTBIN)/ar $(LIBEXEC)/cc1

help:
	@sed -n '1,30p' $(firstword $(MAKEFILE_LIST))
