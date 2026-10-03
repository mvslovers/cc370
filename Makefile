# cc370 -- host-native MVS cross-toolchain build + install.
#
# One driver (cc370) plus five standalone tools
# (as370 / ld370 / ar370 / file370 / xmit370).
# file370 is the read-only inspector (`file`/objdump for the toolchain formats)
# and xmit370 packs a host directory into a TSO TRANSMIT file (and reads one
# back); neither is invoked by the driver, so they get a PATH link but no
# tooldir link.
# Clean cc370-branded layout under $(PREFIX): everything for the target lives in
# one cc370/ tree; only the user-facing binaries sit on PATH.  (The
# i370-ibm-mvspdp triple is an internal config.sub alias; nothing here carries it.)
#
#   bin/cc370                      the driver (the only "driver")
#   bin/{as370,ld370,ar370,file370,xmit370} symlinks -> ../cc370/bin/* (PATH access)
#   libexec/cc370/1.0.0/cc1        the compiler proper (driver-private)
#   libexec/cc370/1.0.0/{as,ld,ar} symlinks beside cc1; the driver's tooldir,
#                                  where it looks up as/ld/ar by short name
#   cc370/bin/{as370,ld370,ar370,file370,xmit370}  the real tool binaries
#   cc370/{include,lib,macros}     the libc370 sysroot (headers, libc.a, crt*.o,
#                                  + macros; as370 finds them via <exedir>/../macros)
#   lib/cc370/1.0.0/               EMPTY but REQUIRED -- this is GCC's libsubdir
#                                  (would hold libgcc; we ship none, so it is empty).
#                                  The compiler driver locates the cc370/ sysroot --
#                                  both <stdio.h> and -lc -- via a path relative to
#                                  it; remove it and the link fails ("cannot find
#                                  -lc"). Created by install-compiler. Leave it be.
#
#   make / make all build the whole toolchain (cc370 + the five tools + man)
#   make tools      only as370 / ld370 / ar370 / file370 / xmit370   [fast]
#   make compiler   configure + build the driver (cc370) and cc1   [slow]
#   make install    build (if needed) + install everything into $(PREFIX)
#   make test       host-side regression suites (as370 + cc370 + xmit370)
#   make clean / uninstall / help

PREFIX  ?= $(HOME)/.local
# cc370 is the toolchain's target name (config.sub aliases it to the real
# i370-ibm-mvspdp backend); it is what shows up in the install paths.
TRIPLE  ?= cc370
# The toolchain's version has ONE source, the VERSION file: the install paths
# here, the compiler's own libexec/lib paths (cc370/gcc/Makefile.in reads the
# same file) and what every binary reports (common/mkversion.sh).  It is not a
# `?=' any more -- a VERSION given on the command line would install into one
# path while the driver looks in another.
VERSION := $(shell tr -d ' \t\r\n' < VERSION)
HOSTCC  ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -Werror
# Release builds (packaging/, #523): HOST_LDFLAGS reaches every host link --
# the tools and the GCC build alike, -static for the Linux tarballs -- and
# CONFIGURE_FLAGS the GCC configure.  Both empty for an ordinary build.
HOST_LDFLAGS    ?=
CONFIGURE_FLAGS ?=

BINDIR  := $(PREFIX)/bin
TGTBIN  := $(PREFIX)/$(TRIPLE)/bin
LIBEXEC := $(PREFIX)/libexec/$(TRIPLE)/$(VERSION)
MANDIR  := $(PREFIX)/share/man/man1

TOOLS   := as370/as370 ld370/ld370 ar370/ar370 file370/file370 xmit370/xmit370 cmplmd370/cmplmd370 dasm370/dasm370 idrdump370/idrdump370
# shared format primitives (CP037 tables, CKD count field, NETDATA records)
COMMON  := common/src/mvs370.c common/src/obj370.c
COMMONH := common/include/mvs370.h common/include/obj370.h
# version + commit, regenerated on every make but REWRITTEN only when either
# changes, so a commit rebuilds what prints it and nothing else (mbt#59)
VERHDR  := common/include/cc370-version.h
# the compiler's own macros (#688), installed by install-macros and used to
# assemble the runtime
MACROS  := macros/pdptop.copy macros/pdpprlg.macro macros/pdpepil.macro
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

.PHONY: FORCE all tools compiler man install install-tools install-compiler install-man \
        test test-as370 test-listref test-cc370 test-corpus test-xmit370 test-cmplmd370 \
        test-dasm370 test-sysroot dist test-version test-macros install-macros runtime test-runtime-host install-runtime clean uninstall help
# `make` / `make all` builds the whole toolchain (cc370 + as370/ld370/ar370 + man).
# `make tools` is the fast path that builds only the three standalone tools.
all: tools compiler runtime man

$(VERHDR): FORCE
	@sh common/mkversion.sh $@
FORCE:

# --- standalone tools (normal single-file C binaries) ---------------------
tools: $(TOOLS)
as370/as370: as370/src/as370.c as370/include/opc_table.h $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Ias370/include -Icommon/include -o $@ as370/src/as370.c $(COMMON) $(HOST_LDFLAGS)
ld370/ld370: ld370/src/ld370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ ld370/src/ld370.c $(COMMON) $(HOST_LDFLAGS)
ar370/ar370: ar370/src/ar370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ ar370/src/ar370.c $(COMMON) $(HOST_LDFLAGS)
file370/file370: file370/src/file370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ file370/src/file370.c $(COMMON) $(HOST_LDFLAGS)
idrdump370/idrdump370: idrdump370/src/idrdump370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ idrdump370/src/idrdump370.c $(COMMON) $(HOST_LDFLAGS)
cmplmd370/cmplmd370: cmplmd370/src/cmplmd370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ cmplmd370/src/cmplmd370.c $(COMMON) $(HOST_LDFLAGS)
xmit370/xmit370: xmit370/src/xmit370.c $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Icommon/include -o $@ xmit370/src/xmit370.c $(COMMON) $(HOST_LDFLAGS)
# dasm370 includes as370's opcode table -- it decodes from the table as370
# encodes from, which is why -Ias370/include is here and not a mistake (#374).
dasm370/dasm370: dasm370/src/dasm370.c as370/include/opc_table.h $(COMMON) $(COMMONH) $(VERHDR)
	$(HOSTCC) $(CFLAGS) -Ias370/include -Icommon/include -o $@ dasm370/src/dasm370.c $(COMMON) $(HOST_LDFLAGS)

# --- man pages (one .pod per tool -> pod2man -> .1) -----------------------
man: $(MAN1)
man/%.1: man/%.pod
	pod2man --section=1 --center="cc370 toolchain" --release="cc370 $(VERSION)" $< > $@

# --- corpus regression gate (#23-lite) ------------------------------------
# Assemble every non-wip libc370 module twice -- with this tree's as370 and with
# one built from a baseline revision (BASE=, default origin/main) -- and report
# which decks moved. Needs the libc370 checkout next to this repo (override with
# LIBC370=/path). A regression guard, not an oracle guard: both sides are as370,
# so it says whether output CHANGED, never whether it is RIGHT. The committed
# IFOX00 decks in tests/ref/ answer that. See as370/tests/corpus/README.md.
test-corpus: as370/as370
	@sh as370/tests/corpus/check.sh

# --- compiler: the cc370 driver + cc1 (a GCC 3.4.6 autotools build) -------
# U= neutralizes a stray `U` in the environment: old-autoconf libiberty emits
# `LIBOBJS = mempcpy$U.o` (ansi2knr suffix, meant to be empty) without defining
# U in the Makefile, so an exported $U (e.g. an MVS userid) leaks in and makes
# `ar` look for mempcpy$U.o. Forcing U= on the command line overrides the env
# and propagates to the recursive sub-makes.
$(BUILD)/config.status:
	mkdir -p $(BUILD)
	cd $(BUILD) && CFLAGS="$(COMPILER_CF) $(HOST_LDFLAGS)" CFLAGS_FOR_BUILD="$(COMPILER_CF)" ../cc370/configure \
	    --target=$(TRIPLE) --enable-languages=c --disable-threads --disable-nls \
	    --disable-shared --without-headers \
	    --with-gcc-version-trigger=../cc370/gcc/version.c $(CONFIGURE_FLAGS)

# --- the compiler runtime, libcc370rt.a (#687) -----------------------------
# The helpers cc370 itself emits calls to -- 64-bit multiply/divide, float <->
# long long, the bit builtins, the -ftrapv checks, __ffssi2 -- the way libgcc
# serves gcc.  Built with the in-tree cc1, as370 and this repository's own
# macros (#688), so it needs nothing from libc370.  -O1 is what libc370
# built them with.
RT_SRC  := $(wildcard runtime/src/*.c)
RTDIR   := $(BUILD)/runtime
RUNTIME := $(RTDIR)/libcc370rt.a
runtime: compiler as370/as370 ar370/ar370
	@$(MAKE) --no-print-directory $(RUNTIME)
$(RUNTIME): $(RT_SRC) $(MACROS) $(CC1) as370/as370 ar370/ar370
	@rm -rf $(RTDIR) && mkdir -p $(RTDIR)
	@set -e; for c in $(RT_SRC); do n=$$(basename "$$c" .c); \
	    $(CC1) -quiet -O1 -std=gnu99 "$$c" -o "$(RTDIR)/$$n.s"; \
	    as370/as370 -I macros -o "$(RTDIR)/$$n.o" "$(RTDIR)/$$n.s"; done
	@ar370/ar370 rc $@ $(RTDIR)/*.o
	@echo "built $@ ($(words $(RT_SRC)) members)"

# Host tests of the runtime's C: the arithmetic, checked against the host's
# native 64-bit operations.  Need no compiler build, so they run in CI.
test-runtime-host:
	@sh runtime/tests/host/run.sh

compiler: $(BUILD)/config.status $(VERHDR)
	$(MAKE) -C $(BUILD) all-gcc U= CFLAGS="$(COMPILER_CF) $(HOST_LDFLAGS)" CFLAGS_FOR_BUILD="$(COMPILER_CF)"

# --- tests ----------------------------------------------------------------
# Host-side regression suites. as370 drives its own (byte-identity to the
# IFOX00 reference decks + its operand regressions); the cc370 codegen suite
# needs the driver-private cc1, so it depends on `compiler`.
# ld370/tests/run.sh is deliberately not wired in: ld370 has no Makefile and
# its suite needs the IEWL/IEBCOPY oracle fixtures.
# xmit370's suite IS wired in: its two external inputs (the TSO TRANSMIT oracle
# and the CBT571 corpus) are optional -- those cases skip themselves and the
# rest of the suite is self-contained.
test: test-version test-macros test-runtime-host test-as370 test-listref test-cc370 test-corpus test-xmit370 test-cmplmd370 test-dasm370 test-idrdump370 test-file370

test-as370:
	@$(MAKE) -C as370 test

# Every binary reports the one version, with the commit the tree is at.
# test-version checks the eight tools; test-version-cc370 adds the driver and
# needs the GCC build, so it is separate (CI runs it on release tags).
test-version: tools
	@sh common/tests/version.sh $(TOOLS)
test-version-cc370: tools compiler
	@sh common/tests/version.sh $(TOOLS) $(DRIVER)

# Column-exact comparison of the as370 -a listing against committed IFOX00
# SYSPRINT references. Separate from test-as370 because it answers a different
# question -- run.sh compares DECKS, this compares the LISTING, and a listing
# defect moves no bytes. It went unrun for months on that reasoning and caught a
# real regression the first time it was pointed at #141's change.
# Case 1 needs the libc370 checkout and skips without it, so this is CI-safe.
# cc370's PDPPRLG/PDPEPIL write out what SAVE/RETURN generated (#688): every
# source that uses them, assembled with libc370's members and with cc370's,
# must give the same deck.  Needs the libc370 checkout beside this one.
test-macros: as370/as370
	@sh macros/tests/check.sh

test-listref: as370/as370
	@sh as370/tests/listref/check.sh

# helpers.sh checks the runtime-helper interface (#685): which helpers each
# construct emits (always), and that each links (only with a sysroot -- by
# default the installed one beside `cc370` on PATH, or SYSROOT=; skipped
# without one).
test-cc370: compiler runtime as370/as370 ld370/ld370
	@sh cc370/tests/run.sh
	@sh cc370/tests/helpers.sh
	@$(MAKE) --no-print-directory test-sysroot

# The second sysroot (#726): an installed tree with no libc370 of its own,
# and a stand-in libc370 linked in as cc370/libc370/.
test-sysroot: tools compiler runtime
	@rm -rf $(BUILD)/sysroot-test
	@$(MAKE) --no-print-directory install-tools install-compiler install-macros install-runtime \
	    PREFIX=$(abspath $(BUILD))/sysroot-test >/dev/null
	@sh cc370/tests/sysroot.sh $(abspath $(BUILD))/sysroot-test

test-xmit370: xmit370/xmit370
	@sh xmit370/tests/run.sh

test-dasm370: dasm370/dasm370 as370/as370
	@sh dasm370/tests/run.sh

test-cmplmd370: cmplmd370/cmplmd370
	@sh cmplmd370/tests/run.sh

test-idrdump370: idrdump370/idrdump370
	@sh idrdump370/tests/run.sh

test-file370: file370/file370
	@sh file370/tests/run.sh

# --- install --------------------------------------------------------------
install: install-tools install-compiler install-macros install-runtime install-man

# Real tool binaries -> $(TGTBIN) (the sysroot bin); $(BINDIR) gets PATH symlinks
# and $(LIBEXEC) gets the driver's tooldir symlinks (both relative -> relocatable).
install-tools: tools
	@mkdir -p $(TGTBIN) $(BINDIR) $(LIBEXEC)
	@install -m 755 as370/as370 $(TGTBIN)/as370
	@install -m 755 ld370/ld370 $(TGTBIN)/ld370
	@install -m 755 ar370/ar370 $(TGTBIN)/ar370
	@install -m 755 file370/file370 $(TGTBIN)/file370
	@install -m 755 cmplmd370/cmplmd370 $(TGTBIN)/cmplmd370
	@install -m 755 xmit370/xmit370 $(TGTBIN)/xmit370
	@install -m 755 dasm370/dasm370 $(TGTBIN)/dasm370
	@install -m 755 idrdump370/idrdump370 $(TGTBIN)/idrdump370
	@ln -sf ../$(TRIPLE)/bin/as370 $(BINDIR)/as370
	@ln -sf ../$(TRIPLE)/bin/ld370 $(BINDIR)/ld370
	@ln -sf ../$(TRIPLE)/bin/ar370 $(BINDIR)/ar370
	@ln -sf ../$(TRIPLE)/bin/file370 $(BINDIR)/file370
	@ln -sf ../$(TRIPLE)/bin/cmplmd370 $(BINDIR)/cmplmd370
	@ln -sf ../$(TRIPLE)/bin/xmit370 $(BINDIR)/xmit370
	@ln -sf ../$(TRIPLE)/bin/dasm370 $(BINDIR)/dasm370
	@ln -sf ../$(TRIPLE)/bin/idrdump370 $(BINDIR)/idrdump370
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

# The compiler's own macros (#688): every .s cc370 writes COPYs PDPTOP and
# wraps each function in PDPPRLG/PDPEPIL.  They go where as370 searches by
# default (<exedir>/../macros), so cc370 output assembles without libc370.
install-macros:
	@mkdir -p $(PREFIX)/$(TRIPLE)/macros
	@install -m 644 $(MACROS) $(PREFIX)/$(TRIPLE)/macros/
	@echo "installed macros -> $(PREFIX)/$(TRIPLE)/macros"

# Beside libc.a, under exactly this name: mbt links -lcc370rt when it finds
# <sysroot>/lib/libcc370rt.a (mbt#138).
install-runtime: runtime
	@mkdir -p $(PREFIX)/$(TRIPLE)/lib
	@install -m 644 $(RUNTIME) $(PREFIX)/$(TRIPLE)/lib/libcc370rt.a
	@echo "installed runtime -> $(PREFIX)/$(TRIPLE)/lib/libcc370rt.a"

install-man: man
	@mkdir -p $(MANDIR)
	@install -m 644 $(MAN1) $(MANDIR)/
	@echo "installed man pages -> $(MANDIR)"

# --- release tarball (#523) ---------------------------------------------------
# The whole installation tree, relocatable as `make install' leaves it: unpack
# it anywhere and bin/cc370 finds its own pieces.  libc370 is not in it; it
# ships as its own sysroot tarball (libc370#326) and unpacks into cc370/.
# The release binaries are stripped (#718): the build keeps -g for development,
# and `make install' leaves it in; a release tree carries no debug info.  Only
# the host executables -- the driver, cc1 and the real tool binaries; bin/ and
# the tooldir hold symlinks to them -- and never libcc370rt.a, an archive of
# S/370 object decks the host strip does not understand.
PLATFORM ?= $(shell sh packaging/platform.sh)
DISTNAME := cc370-$(VERSION)-$(PLATFORM)
DISTDIR  := dist
STRIP    ?= strip
dist: tools compiler runtime man
	@rm -rf $(DISTDIR)/$(DISTNAME) $(DISTDIR)/$(DISTNAME).tar.gz && mkdir -p $(DISTDIR)
	@$(MAKE) --no-print-directory install PREFIX=$(abspath $(DISTDIR))/$(DISTNAME) >/dev/null
	@$(STRIP) $(DISTDIR)/$(DISTNAME)/bin/cc370 \
	    $(DISTDIR)/$(DISTNAME)/libexec/$(TRIPLE)/$(VERSION)/cc1 \
	    $(addprefix $(DISTDIR)/$(DISTNAME)/$(TRIPLE)/bin/,$(notdir $(TOOLS)))
	@tar -C $(DISTDIR) -czf $(DISTDIR)/$(DISTNAME).tar.gz $(DISTNAME)
	@echo "built $(DISTDIR)/$(DISTNAME).tar.gz"

clean:
	rm -rf $(BUILD)
	rm -f $(TOOLS) $(MAN1) $(VERHDR)

uninstall:
	rm -f $(BINDIR)/cc370 $(BINDIR)/as370 $(BINDIR)/ld370 $(BINDIR)/ar370 $(BINDIR)/file370 \
	      $(BINDIR)/xmit370 $(BINDIR)/cmplmd370 $(BINDIR)/dasm370 $(BINDIR)/idrdump370 \
	      $(TGTBIN)/as370 $(TGTBIN)/ld370 $(TGTBIN)/ar370 $(TGTBIN)/file370 $(TGTBIN)/xmit370 \
	      $(TGTBIN)/cmplmd370 $(TGTBIN)/dasm370 $(TGTBIN)/idrdump370 \
	      $(LIBEXEC)/as $(LIBEXEC)/ld $(LIBEXEC)/ar $(LIBEXEC)/cc1 \
	      $(addprefix $(PREFIX)/$(TRIPLE)/macros/,$(notdir $(MACROS))) \
	      $(PREFIX)/$(TRIPLE)/lib/libcc370rt.a \
	      $(MANDIR)/cc370.1 $(MANDIR)/as370.1 $(MANDIR)/ld370.1 $(MANDIR)/ar370.1 \
	      $(MANDIR)/file370.1 $(MANDIR)/xmit370.1 $(MANDIR)/dasm370.1

help:
	@sed -n '1,30p' $(firstword $(MAKEFILE_LIST))
