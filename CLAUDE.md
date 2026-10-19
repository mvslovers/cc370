# CLAUDE.md

Extends the ecosystem root `~/repos/mvs/CLAUDE.md` (platform constraints, git
and release-text rules, autonomy); nothing here repeats it.

## Project Overview

cc370 compiles C source to IBM System/370 HLASM assembler (`.s` files) for MVS 3.8j. It is a **cross-compiler**: it runs on the host (macOS/Linux) and emits mainframe assembler.

**The goal: a fully host-native MVS cross-toolchain.** Historically the `.s` was uploaded to the IBM assembler (**IFOX00**) on the target. `as370` produces OS/360 object decks **on the host**, byte-identical to IFOX00, and `ld370` links them into the load module, so the only thing that touches MVS is the final load module. Components:

| Tool | Role |
|------|------|
| **cc370** | C → i370 HLASM `.s` (the GCC 3.4.6 fork; `cc370/gcc/`) |
| **as370** | `.s`/`.asm` → OS/360 OBJ deck (`as370/src/as370.c`) |
| **ld370** | OBJ decks → MVS load module (replace IEWL) + automatic library call (`-l`/`-L` over `.a`) + `-iebcopy`/`-xmit` host→MVS transport (`ld370/src/ld370.c`) |
| **ar370** | OBJ decks → `.a` archive + ESD symbol index (`ar370/src/ar370.c`) |
| **file370** | identify + analyze any toolchain format (`file370/src/file370.c`); read-only, not driven by cc370 |
| **xmit370** | host directory → TSO TRANSMIT of a **source** PDS, and back (`xmit370/src/xmit370.c`); format delta: `internals/xmit-source-pds.md` |
| **dasm370** | disassemble a control section of an OS/360 object deck (`dasm370/src/dasm370.c`; decodes from as370's opcode table) |
| **cmplmd370** | does this object deck match that CSECT of a load module, byte for byte (`cmplmd370/src/cmplmd370.c`) |
| **idrdump370** | walk a load-module member's IDR chain, decoding HMASPZAP entries (`idrdump370/src/idrdump370.c`) |

Shared format primitives (CP037 tables, CKD count field, NETDATA records) are in
`common/`; the compiler's own runtime helpers (`libcc370rt.a`) in `runtime/`;
its prologue macros (`PDPTOP`/`PDPPRLG`/`PDPEPIL`) in `macros/`; man pages in
`man/*.pod`.

**This repo is the v2.0 toolchain:** GCC **3.4.6** for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`), slimmed to the i370 target, plus the host tools. Imported from the `i370-gcc` fork (snapshot of `mvslovers/i370-gcc` @ `0710af0c`; see README "Provenance"). The earlier GCC **3.2.3**-based **c2asm370 v1.x** lives in the frozen `mvslovers/c2asm370` repo (kept as a fallback so existing ecosystem projects keep building against the old name); the matching v1.x libc is the frozen `crent370`. The current libc is `mvslovers/libc370`.

## Build

The top-level `Makefile` drives everything (plain `make`, not mbt):

```sh
make            # the whole toolchain: tools + compiler + runtime + man
make tools      # only the standalone tools   [fast]
make compiler   # configure + build the driver (cc370) and cc1   [slow]
make install    # build (if needed) + install into $(PREFIX) (default ~/.local)
make test       # host-side regression suites
make dist       # relocatable release tarball
make help
```

Install layout (clean cc370-branded, under `$(PREFIX)`): everything for the target
lives in one `cc370/` tree; only the user-facing binaries sit on PATH. `<VERSION>`
below is the content of the `VERSION` file.

- `bin/cc370` — the driver (the *only* driver). `bin/{as370,ld370,ar370,file370,…}`
  are symlinks → `../cc370/bin/*` for PATH access.
- `libexec/cc370/<VERSION>/cc1` — the driver-private compiler proper; beside it,
  `{as,ld,ar}` symlinks → `../../../cc370/bin/*` are the driver's **tooldir** (it
  looks up `as`/`ld`/`ar` there by short name). The other tools are *not* here —
  the driver never invokes them (PATH-link only).
- `cc370/bin/*370` — the **real** tool binaries.
- `cc370/{include,lib,macros}` — the libc370 **sysroot** (installed by
  `make -C ../libc370 install`): cc370 finds `<stdio.h>` with no `-I`, ld370 `-lc`
  pulls `libc.a`, and as370 (real in `cc370/bin`) finds the macros via its
  `<exedir>/../macros` default. cc370's own `install-macros` puts its prologue
  macros there too, and `install-runtime` puts `lib/libcc370rt.a` beside `libc.a`.
- `cc370/libc370/{include,lib,macros}` — optional **second sysroot** (#726): a
  libc370 kept in its own tree and linked in here (the Homebrew keg layout).
  Searched after the tree's own `include/`, `lib/`, `macros/` -- by cc1
  (`CC370_LIBC370_INCLUDE_DIR`), the driver's startfile prefixes (crt0.o, `-L`)
  and as370's default macro path. `make test-sysroot` checks all four.
- `lib/cc370/<VERSION>/` — GCC's **libsubdir**. **Empty but required — intentional,
  not a bug.** It would hold libgcc; we ship none, so it stays empty. The driver
  locates the whole `cc370/` sysroot (headers AND `-lc`) via a path relative to
  it, so removing it gives "cannot find -lc". `install-compiler` creates it.
  (Only a `--with-sysroot` reconfigure could eliminate it; not worth it.)

The target name is **`cc370`** — a `config.sub` alias (added near the `mvs)` arm)
that canonicalizes to the real `i370-ibm-mvspdp` backend, so `config.gcc` is
unchanged but `target_noncanonical` (hence every install path and `-dumpmachine`)
is the clean `cc370`. The path version (read from the repository's
`VERSION` file by both the top-level `Makefile` and `gcc/Makefile.in`'s
`version :=`) is a product version, decoupled from the GCC version (still 3.4.6, in
`version.c`); it is not an ABI gate. The `gcc/` path level is dropped in
`Makefile.in` (`libsubdir`/`libexecsubdir`/`STANDARD_*_PREFIX`, `unlibsubdir=../..`).
The compiler is a GCC 3.4.6 fork (old K&R-ish C); `make compiler` passes the
needed `-w`/`-Wno-*`/`-std=gnu89` flags (`COMPILER_CF`) so it builds clean on a
modern host gcc. Builds on x86-64 and ARM64.

**Output format (`-flinker-output=`).** `cc370 foo.c -o app` writes a load-module
member (LMOD). `-flinker-output=xmit` *additionally* emits `app.xmit` (TSO
TRANSMIT/NETDATA); `=iebcopy` emits `app.iebcopy` (IEBCOPY unloaded PDS). It is flag-
driven, not -o-extension-driven. Mechanism: `flinker-output=` is registered in
`gcc/common.opt` (`Common Joined`) with a no-op `case OPT_flinker_output_` in
`gcc/opts.c` (else `common_handle_option`'s `default: abort()` ICEs); `LINK_SPEC`
(`mvspdp.h`) maps the value to ld370's `-xmit`/`-iebcopy` via
`%{flinker-output=xmit:-xmit}`. ld370 itself is flag-driven too: `-o OUT` =
member, `-xmit`/`-iebcopy` (no-arg) add `OUT.xmit`/`OUT.iebcopy`.

**Optimization: `-O1` validated, `-Os` experimental, `-O2`/`-O3` unsupported.** `-O1` is validated correct and is mbt's default. Unit-at-a-time and strict aliasing are **off by default** via `OPTIMIZATION_OPTIONS` in `i370.h` (#590, #592); `-funit-at-a-time`/`-fstrict-aliasing` turn them back on. `-Os` stays experimental and each project validates it itself. History: `internals/toolchain-history.md`.

## Testing

`make test` runs the host-side regression suites (the list and what each needs
is in the `Makefile` comments): among them `test-as370` (decks against IFOX00
references), `test-libcorpus` (as370 against IFOX00 on the frozen libc370
corpus, all in the repo), `test-listref` (the `-a` listing against IFOX00
SYSPRINT), `test-cc370` (codegen, runtime helpers, sysroot, driver; needs the
compiler build), `test-corpus` (as370 against a baseline revision — says
whether output *changed*, never whether it is right), and one suite per tool.
Some cases need the libc370 checkout beside this repo and skip without it.
`ld370/tests/run.sh` is deliberately not wired in (needs the IEWL/IEBCOPY
oracle fixtures).

## Architecture

Standard GCC pipeline: C source → lexer/parser → RTL → optimization → assembler output. Output is EBCDIC, HLASM syntax, MVS calling conventions (`COPY PDPTOP` / `PDPPRLG` / `PDPEPIL`), libc370-compatible.

### Key directories

- **`cc370/gcc/config/i370/`** — the i370/mvspdp target backend. **Check here first for codegen bugs.**
- **`cc370/gcc/`** — GCC 3.4.6 core (C frontend, RTL, optimization passes, `cppcharset.c` for escape/charset handling). Largely upstream.
- **`cc370/libiberty/`, `cc370/include/`** — GNU support library + shared internal headers (GCC build deps).

Unlike v1.x (3.2.3), v2.0 does **not** shadow `toplev.c`/`varasm.c`/`final.c` in the target dir — the target is self-contained in `cc370/gcc/config/i370/`.

### cc370/gcc/config/i370 (primary modification area)

| File | Purpose |
|------|---------|
| `i370.c` | Machine definition — RTL→assembly; charset tables `i370_ascii_to_ebcdic` / `i370_ebcdic_to_ascii` |
| `i370.h` | Target constants, registers, `ASM_OUTPUT_ASCII`, charset MAP_OUTCHAR/MAP_INCHAR macros |
| `i370.md` | Machine description (insn patterns) |
| `i370-c.c` | C frontend pragma handling |
| `mvspdp.h` | The `i370-ibm-mvspdp` subtarget header (`TARGET_PDPMAC`) |
| `t-i370*` | Makefile fragments |

### Charset (EBCDIC CP037 + ecosystem NEL)

- Char constants and string literals map to **CP037**. String literals are **Latin-1** in the STRING_CST — the default narrow execution set is `ISO-8859-1` (`DEFAULT_NARROW_CHARSET`, `cppcharset.c`; #511), one byte per character — and convert to EBCDIC at **output** time (`ASM_OUTPUT_ASCII`): printables → `C'..'` (converted by the ASCII→EBCDIC file transfer on upload), control/variant/`&` → `X'<MAP_OUTCHAR>'`. ASCII is a subset of Latin-1, so inline-asm templates stay readable and unchanged in the `.s`; an *EBCDIC* `-fexec-charset` would rewrite them and stays unusable.
- Newline `\n` → **NEL `0x15`** — the mvslovers ecosystem newline, byte-identical to httpd `cp037_atoe`/`cp037_etoa` (mvsMF upload, HTTP output, UFS, z/OS USS). NOT pure CP037 LF `0x25` (which breaks HTTP CRLF: `etoa[0x25]=0x85`, not LF).
- `\x`/`\NNN` escapes are pre-imaged in `cppcharset.c` (via `MAP_INCHAR`) so the output pass round-trips them to the literal byte — binary string data (e.g. crent dataset-I/O flags) is preserved.
- A char has one runtime value whether it is a constant or sits in a string (`'\n' == "\n"[0]` at runtime). Every place that reads a string byte *as a value* instead of outputting it — the `-O1` folds of `"\n"[0]` / `*"a"` / `const char t[] = "…"; t[0]` (`expr.c`), the builtin folds (`printf("c")`→`putchar`, `strcmp` of two literals, `builtins.c`), and a designator splitting a string initialiser (`c-typeck.c`) — must map it through `TARGET_STR_BYTE` (`defaults.h`, the same table as the output). Character constants get their value in one place, `narrow_str_to_charconst` / `wide_str_to_charconst` (`cppcharset.c`), so the code and `#if` agree (`#if 'A' == 193` is true). A wide character above 0xFF keeps its Unicode code point (`preimage_wide_above_byte`); up to 0xFF it is Latin-1 mapped to CP037. Until #477/#487 these took the host byte; a new such site is the same bug again.

**Which table applies is decided by the ingress path, and that decision stands:
everything arriving over UFS is IBM-1047 (as USS on z/OS is), everything arriving
over MVS is CP037.** cc370 and as370 are on the MVS side — their output reaches
the system as datasets through the mvsMF upload path — so both use CP037, and
they agree byte for byte: `i370_ascii_to_ebcdic` (`i370.c:63`) and as370's `a2e`
both map `[` to `X'BA'` and `]` to `X'BB'`.

Source that reaches a guest some other way can therefore differ in exactly those
variant code points without either assembler being wrong. Submitting ASCII
through Hercules' card reader produces `X'AD'`/`X'BD'` — the 1047 assignment —
and that is a property of the transport, not of the translator. Measured across
65 generated modules: 86 occurrences in 19 of them, and no other byte difference
anywhere (mvslovers/cc370#74). Do not "fix" one side to match the other; check
which path the source travelled first.

**The host side of the table is Latin-1, and the source may be either Latin-1 or
UTF-8.** Both tools decide per file: valid UTF-8 is taken as UTF-8, anything
else as Latin-1, and the host locale plays no part. as370 decodes to one byte
per character; above U+00FF is severity 4 on the card and 8 in a constant
(`as370/README.md`, "Source encoding"; #483). cc370 reads UTF-8 (a Latin-1 file
is converted on input, a leading BOM dropped — `_cpp_convert_input`) and turns a
narrow string or character constant into Latin-1; above U+00FF there is an
**error** naming the code point, comments may hold anything (#511). An explicit
`-finput-charset` / `-fexec-charset` overrides either rule. Both encodings are
in the ecosystem side by side — Latin-1 `¬` in libc370/brexx370 macros and
2,089 MVSBLD modules, UTF-8 in newer sources — so never decode everything as
UTF-8.

### Key preprocessor defines

`TARGET_PDPMAC`, `TARGET_EBCDIC`, `TARGET_HLASM`, `TARGET_MVS`, `I370_IFOX_COLUMNS`, `IN_GCC`, `HAVE_CONFIG_H`.

## Important Notes

- `cc370/gcc/c-parse.c` is generated from `c-parse.in`; a pre-generated parser / dummy Makefile rule avoids running yacc.
- Symbol names in address constants must be emitted via `output_addr_const` (not `ASM_OUTPUT_LABELREF` on the raw `XSTR`) so the leading `*` of an `asm()`-named extern is stripped — taking the **address** of an asm-named extern otherwise emits invalid `=V(*NAME)` → IFOX IFO161 (fixed in v2.0).
- Output uses EBCDIC encoding and HLASM syntax with MVS calling conventions.
- A helper insn that emits `DR`/`D` or `MR`/`M` over an even/odd pair must be an `unspec` (`i370_divmod`, `i370_mult`), never a `(div|mod|mult):DI` set: that is exactly the `REG_EQUAL` note a `__divdi3`/`__moddi3`/`__muldi3` libcall carries, and `dead_libcall_p` (`cse.c`) swaps the call for any note that recognises — `long long / 10` became one 32-bit `DR` (S0C9) until #467, at `-O0` as well.

## as370 — Host-Native MVS Assembler

`as370/src/as370.c` is a single-file host-native MVS **Assembler-XF (IFOX00)** clone: macro preprocessor + two-pass core + OS/360 OBJ writer (80-byte EBCDIC ESD/TXT/RLD/END cards). It runs on macOS/Linux and produces object decks **byte-identical to IFOX00**.

- **Identity:** tool name `as370`, product id `ASM370`. `as370 --version` (or `-V`; `-v` is verbose since #811) → `as370 <VERSION> (<commit>)` -- the toolchain version from `VERSION`, as every tool reports it (#523).
- **Build:** `make tools` (`-O2 -Wall -Wextra -Werror`, warning-clean under gcc-14 + clang).
- **CLI:** z/OS-`as`-aligned. `--help` usage; RC convention from IFOX `JERMSGCD` (0 clean / 4 warn / 8 error / 12 severe / 16 terminal); silent on success (no noise when called from cc370). Friendly per-statement diagnostic: prints the true source line + `ERROR: Undefined operation code in line N - op`.
- **Macro path:** `-I <dir>` (repeatable); default `<exedir>/../macros`. The ecosystem needs libc370 `maclib` + `sysmac` and SYS1.MACLIB members.
- **Validation = byte-identity to IFOX00**, the authoritative oracle. The END card's translator IDR (`15741SC103`+date) is IFOX-specific and intentionally not reproduced; "byte-identical" means ESD/TXT/RLD content. The full patched IFOX source is the reference (NOT committed — IBM proprietary; `~/repos/mvs/ifox-src/all/`).
- **`-a` listing:** ASCII, column-exact to IFOX SYSPRINT for the ESD + SOURCE + RLD sections and the CROSS-REFERENCE + LITERAL CROSS-REFERENCE pages (#538; `--xref=short` = `XREF(SHORT)`). Diagnostics / statistics pages not yet produced.

## Releases and the libc370 contract

**Read [`internals/releasing.md`](internals/releasing.md) before tagging a release, adding
or renaming a runtime helper, or changing the prologue macros.** It holds who
owns what between cc370 and libc370, which version needs which, and the
release checklist (tag only after the coordinating mbt session's go). libc370
keeps the same file for its side.

## Read when relevant

| Before you … | read |
|---|---|
| tag a release, touch a runtime helper or the prologue macros | `internals/releasing.md` |
| pick up open work or re-rank it | `TODO.md` (order) and `gh issue list` (state) |
| work on ld370's output: load module, unload, XMIT | `internals/load-module-format.md`, `internals/unload-format.md`, `internals/xmit-format.md`, `internals/ld370-iewl-divergences.md` |
| work on as370 decks or the object format | `internals/object-module-format.md`, `internals/assembler-g-comparison.md` |
| touch entry points or fetch of large modules | `internals/entry-point-resolution.md`, `internals/multitext-fetch-truncation.md`, `internals/measurements/` |
| need the history of ld370 (`--pack`, S106-0F, BLKSIZE, autocall) or of `-Os` | `internals/toolchain-history.md` |
| plan a new tool | `internals/tool-roadmap.md` |

## Workflow

On top of the root rules: bugfix branches are `fix/<description>`; commit messages use Conventional Commits
(`fix: …`, `docs(TODO): …`, `chore: …`); when closing an issue, leave a short
comment with the root cause and the fix.
