# cc370

A **host-native cross-toolchain for MVS 3.8j** (TK4-, TK5, MVS/CE): compile,
assemble, link and package MVS programs entirely on the host (macOS / Linux), so
the only thing that touches the mainframe is the finished load module.

```sh
cc370 hello.c -o hello.xmit      # compile + assemble + link + package, one command
```

That `hello.xmit` ships to MVS and is installed into a load library with one
`RECV370` step — no IFOX00, no IEWL, no IEBCOPY, no JCL round-trip.

## The four tools

| Tool | Role | Built from |
|------|------|------------|
| **cc370** | the driver + C → i370 HLASM compiler (`gcc/`) | a GCC 3.4.6 fork for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`) |
| **as370** | `.s`/`.asm` → OS/360 object deck — byte-identical to IBM's IFOX00 | `as/as370.c` |
| **ld370** | object decks → MVS load module (replaces IEWL) + automatic library call + `--unload`/`--xmit` host→MVS transport | `ld/ld370.c` |
| **ar370** | object decks → `.a` archive with an ESD symbol index | `ld/ar370.c` |

`cc370` is the single front-end; `as370`/`ld370`/`ar370` are ordinary binaries it
drives (and which you can also run standalone). The C library it links against is
**[libc370](https://github.com/mvslovers/libc370)**, installed into the cc370
sysroot — see *Sysroot* below.

## Build & install

GCC 3.4.6 is old K&R-ish C; a modern clang/gcc host must be told not to error on
it. The top-level `Makefile` wraps the whole thing:

```sh
make            # build the tools (as370, ld370, ar370)
make gcc        # build the driver (cc370) + the compiler proper (cc1), out-of-tree in build/
make install    # install everything under $(PREFIX)  (default ~/.local)
```

Knobs: `PREFIX` (default `~/.local`), `TRIPLE` (default `i370-ibm-mvspdp`),
`GCCVER` (default `3.4.6`). After `make install` you get:

```
<prefix>/bin/cc370                              the one driver (+ PATH symlinks for the tools)
<prefix>/libexec/gcc/<triple>/<ver>/cc1         the compiler proper
<prefix>/<triple>/bin/{as370,ld370,ar370}       the tools (+ as/ld/ar the driver invokes)
```

Builds on x86-64 and ARM64.

### Sysroot — where cc370 finds the libc

cc370 searches `<prefix>/<triple>/{include,lib}` by default (the path is derived
from the driver itself via `-dumpmachine` / `-print-prog-name=cc1`, so renaming
the triple later needs no edit). [libc370](https://github.com/mvslovers/libc370)
drops its headers, `libc.a`, the `crt0/1/m.o` startfiles and the assembler macros
there, after which the toolchain is self-contained:

```sh
make -C ../libc370 install        # populate the sysroot once
cc370 hello.c -o hello.xmit       # no -I, no -L, no -lc needed
```

## Optimization: `-O1` only

`-O2`/`-Os`/`-O3` are **unsafe** on this backend. At `-O2`+ the
`-funit-at-a-time` DCE drops `static` tables whose address is held by a global
pointer → dangling address constants → assembler RC=8; `-Os` additionally
miscompiles the rexx parser (loops → S322). `-O1` is validated correct (rexx370
TSTALLB 84/84, 0 ABEND). This — not any memory limit — is the reason for
"`-O1` only".

## Layout

```
gcc/config/i370/   the i370/mvspdp target backend  — check here first for codegen bugs
gcc/               GCC 3.4.6 core (C front end, RTL, optimizer), largely upstream
libiberty/ include/ GNU support library + shared headers
as/                as370 — host-native MVS assembler  (as/README.md)
ld/                ld370 + ar370 — host-native linker + archiver
docs/              object / load-module / unload / xmit formats + roadmap
```

Deep dives: [`CLAUDE.md`](CLAUDE.md) (architecture + gotchas),
[`as/README.md`](as/README.md), and `docs/` (the on-the-wire formats).

## Provenance

The compiler is a fork of GCC **3.4.6** — the last GCC to carry the i370 machine
definition — for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`: HLASM/EBCDIC,
`COPY PDPTOP` / `PDPPRLG` / `PDPEPIL`, [libc370](https://github.com/mvslovers/libc370)-compatible
calling conventions), slimmed to that one target.

It descends from the gccmvs / [i370-gcc](https://github.com/linas/i370-gcc) line
(Paul Edwards, Dave Pitts, and others). Specifically, this tree is a snapshot of
`mvslovers/i370-gcc` @ `feature/ebcdic-char-constants` (commit `0710af0c`),
brought in as v2.0 because the upstream PRs to linas went unanswered — so the
compiler is developed against the ecosystem's own requirements from here on. The
earlier GCC 3.2.3-based generation is the frozen `mvslovers/c2asm370` repo
(**v1.x**), kept as a fallback for projects still on the old name.

What this snapshot carries over stock GCC 3.4.6:

- **EBCDIC charset (CP037 + ecosystem NEL):** char constants and string literals
  map to CP037; `\n` maps to EBCDIC NEL `0x15` (byte-identical to the ecosystem
  httpd `cp037_atoe`/`cp037_etoa`, so it matches mvsMF upload and HTTP output);
  `\x..`/`\NNN` escapes stay binary-literal.
- **Codegen for IFOX00:** fixed-column assembler text, valid MVS symbol names for
  private statics, signed 32-bit literals; the `asm()`-extern address-of fix.
- **Host portability:** builds on macOS and Linux, x86-64 and ARM64, modern
  clang/gcc-14 hosts.
- **Slimmed to i370:** the tree was cut from ~20 640 to ~1 100 tracked files
  (other GCC targets, other-language front ends, the test suite, other-language
  runtimes), then the leftover build cruft (changelogs, contrib, stale objects).

### Building GCC by hand

`make gcc` wraps this; the equivalent direct invocation (GCC 3.4.6 needs the
old-C `-Wno-*` flags on a modern host):

```sh
CF="-g -O0 -fcommon -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration \
    -Wno-int-conversion -Wno-error -Wno-return-type -Wno-deprecated-non-prototype"
mkdir build && cd build
CFLAGS="$CF" CFLAGS_FOR_BUILD="$CF" ../configure \
  --target=i370-ibm-mvspdp --enable-languages=c \
  --disable-threads --disable-nls --disable-shared --without-headers
make all-gcc CFLAGS="$CF" CFLAGS_FOR_BUILD="$CF"   # -> build/gcc/{cc1,xgcc}
```

Maintained by the [mvslovers](https://github.com/mvslovers) community.
