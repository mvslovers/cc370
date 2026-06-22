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

Deep dives: [`V2.0.0-README.md`](V2.0.0-README.md) (provenance of the GCC fork),
[`CLAUDE.md`](CLAUDE.md) (architecture + gotchas), [`as/README.md`](as/README.md),
and `docs/` (the on-the-wire formats).

## Provenance

The compiler is a fork of GCC **3.4.6** — the last GCC to carry the i370 machine
definition — for the `i370-ibm-mvspdp` HLASM target, slimmed to that one target.
It descends from the gccmvs / [i370-gcc](https://github.com/linas/i370-gcc) line
(Paul Edwards, Dave Pitts, and others) and from the earlier GCC 3.2.3-based
**c2asm370** v1.x. The charset and ABI match the
[libc370](https://github.com/mvslovers/libc370) runtime (EBCDIC CP037 with the
ecosystem NEL newline).

Maintained by the [mvslovers](https://github.com/mvslovers) community.
