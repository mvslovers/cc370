# cc370 -- host-native MVS cross-toolchain build + install.
#
# One driver (cc370) plus three standalone tools (as370 / ld370 / ar370).
# Clean cc370-branded layout under $(PREFIX) (the i370-ibm-mvspdp triple is an
# internal config.sub alias; nothing user-facing carries it):
#
#   bin/cc370                      the driver (the only "driver")
#   bin/{as370,ld370,ar370}        the real tools, on PATH
#   libexec/cc370/1.0.0/cc1        the compiler proper (driver-private)
#   cc370/bin/{as,ld,ar}           relative symlinks -> ../../bin/* ; the driver's
#                                  tooldir, where it looks up as/ld/ar by short name
#   cc370/{include,lib}            the libc370 compiler sysroot
#   macros/                        as370's macros (libc370); found via <exedir>/../macros
#
# as370's real binary is in bin/, so its default macro path <exedir>/../macros
# resolves to $(PREFIX)/macros (where libc370 installs them).
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
	mkdir -p $(BINDIR) $(TGTBIN)
	install -m 755 as370/as370 $(BINDIR)/as370    # the real binaries live on PATH
	install -m 755 ld370/ld370 $(BINDIR)/ld370
	install -m 755 ar370/ar370 $(BINDIR)/ar370
	ln -sf ../../bin/as370 $(TGTBIN)/as    # the cc370 driver invokes as/ld/ar from
	ln -sf ../../bin/ld370 $(TGTBIN)/ld    # its tooldir ($(TRIPLE)/bin); relative
	ln -sf ../../bin/ar370 $(TGTBIN)/ar    # symlinks keep the tree relocatable
	@echo "installed tools -> $(BINDIR) (driver tooldir links in $(TGTBIN))"

# install cc1 + the driver renamed to cc370 (needs a prior `make gcc`)
install-gcc:
	@test -x $(DRIVER) -a -x $(CC1) || { \
	  echo "no driver/cc1 in $(BUILD) -- run 'make gcc' first (slow)"; exit 1; }
	mkdir -p $(LIBEXEC) $(BINDIR)
	install -m 755 $(CC1) $(LIBEXEC)/cc1
	install -m 755 $(DRIVER) $(BINDIR)/cc370
	# The driver locates the tooldir ($(TRIPLE)/bin, where it finds as/ld) by a
	# path relative to its libsubdir ($(PREFIX)/lib/$(TRIPLE)/$(GCCVER)). We ship
	# no target libs/specs there, but the dir must exist for that '..' traversal
	# to resolve -- otherwise the driver falls back to the host assembler.
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
	      $(TGTBIN)/as $(TGTBIN)/ld $(TGTBIN)/ar $(LIBEXEC)/cc1 \
	      $(MANDIR)/cc370.1 $(MANDIR)/as370.1 $(MANDIR)/ld370.1 $(MANDIR)/ar370.1

help:
	@sed -n '1,30p' $(firstword $(MAKEFILE_LIST))
