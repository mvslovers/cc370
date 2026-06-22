# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

cc370 compiles C source to IBM System/370 HLASM assembler (`.s` files) for MVS 3.8j. It is a **cross-compiler**: it runs on the host (macOS/Linux) and emits mainframe assembler.

**The goal (v2.0): a fully host-native MVS cross-toolchain.** Historically the `.s` was uploaded to the IBM assembler (**IFOX00**) on the target. v2.0 adds **`as370`** (`as370/src/as370.c`) — a host-native MVS Assembler-XF clone that produces OS/360 object decks **on the host**, byte-identical to IFOX00. The endgame is to compile, assemble, **and link** on the host so the only thing that touches MVS is the final load module (eventually nothing). Components:

| Tool | Role | Status |
|------|------|--------|
| **cc370** | C → i370 HLASM `.s` (the GCC 3.4.6 fork; `cc370/gcc/`) | works; `-O1` only |
| **as370** | `.s`/`.asm` → OS/360 OBJ deck (`as370/src/as370.c`) | **byte-identical to IFOX00 (950 modules); links + runs on MVS** |
| **ld370** | OBJ decks → MVS load module (replace IEWL) + automatic library call (`-l`/`-L` over `.a`) + `--unload`/`--xmit` host→MVS transport (`ld370/src/ld370.c`) | member byte-identical to IEWL; `--unload`/`--xmit` byte-identical to their oracles (XMIT modulo timestamp); autocall validated (single + transitive pull == explicit link). **End-to-end on real MVS: `as370→ld370→--xmit` → upload → RECV370 → runs, RC=7 (Stage 2 done)** |
| **ar370** | OBJ decks → `.a` archive + ESD symbol index (`ar370/src/ar370.c`) | standard `ar` container (host-inspectable) with a GNU `/`-member symbol table built from each deck's ESD (variable-length names, long-symbol-ready); the static-library ld370 autocalls against |

**End-to-end validated on real MVS (2026-06-18):** `cc370 → as370` built ctest locally (no IFOX00), the decks linked with IEWL (RC=0) and ran (`PGM=CTESTH`) with **RC=0** (all charset checks pass). See `as370/` and the [as370 section](#as370--host-native-mvs-assembler).

**This repo is the v2.0 toolchain:** GCC **3.4.6** for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`), slimmed to the i370 target, plus as370/ld370/ar370. Imported from the `i370-gcc` fork (snapshot of `mvslovers/i370-gcc` @ `0710af0c`; see README "Provenance"). The earlier GCC **3.2.3**-based **c2asm370 v1.x** lives in the frozen `mvslovers/c2asm370` repo (kept as a fallback so existing ecosystem projects keep building against the old name); the matching v1.x libc is the frozen `crent370`. The current libc is `mvslovers/libc370`.

## Build (v2.0 — C-only cross-compiler, modern macOS/Linux host)

The top-level `Makefile` drives everything. The toolchain is **one driver
(`cc370`) plus three standalone tools (`as370`/`ld370`/`ar370`)**:

```sh
make            # build the WHOLE toolchain: cc370 + as370/ld370/ar370
make tools      # only the three standalone tools   [fast]
make compiler   # configure + build the driver (cc370) and cc1   [slow]
make install    # build (if needed) + install into $(PREFIX) (default ~/.local)
```

Install layout (clean cc370-branded, under `$(PREFIX)`): everything for the target
lives in one `cc370/` tree; only the user-facing binaries sit on PATH.

- `bin/cc370` — the driver (the *only* driver). `bin/{as370,ld370,ar370}` are
  symlinks → `../cc370/bin/*` for PATH access.
- `libexec/cc370/1.0.0/cc1` — the driver-private compiler proper; beside it,
  `{as,ld,ar}` symlinks → `../../../cc370/bin/*` are the driver's **tooldir** (it
  looks up `as`/`ld`/`ar` there by short name).
- `cc370/bin/{as370,ld370,ar370}` — the **real** tool binaries.
- `cc370/{include,lib,macros}` — the libc370 **sysroot** (installed by
  `make -C ../libc370 install`): cc370 finds `<stdio.h>` with no `-I`, ld370 `-lc`
  pulls `libc.a`, and as370 (real in `cc370/bin`) finds the macros via its
  `<exedir>/../macros` default.
- `lib/cc370/1.0.0/` — GCC's **libsubdir**. **Empty but required — intentional,
  not a bug.** It would hold libgcc; we ship none, so it stays empty. The driver
  locates the whole `cc370/` sysroot (headers AND `-lc`) via a path relative to
  it, so removing it gives "cannot find -lc". `install-compiler` creates it.
  (Only a `--with-sysroot` reconfigure could eliminate it; not worth it.)

The target name is **`cc370`** — a `config.sub` alias (added near the `mvs)` arm)
that canonicalizes to the real `i370-ibm-mvspdp` backend, so `config.gcc` is
unchanged but `target_noncanonical` (hence every install path and `-dumpmachine`)
is the clean `cc370`. The path version (`1.0.0`, from `gcc/Makefile.in`'s
`version=`) is a product version, decoupled from the GCC version (still 3.4.6, in
`version.c`); it is not an ABI gate. The `gcc/` path level is dropped in
`Makefile.in` (`libsubdir`/`libexecsubdir`/`STANDARD_*_PREFIX`, `unlibsubdir=../..`).
The compiler is a GCC 3.4.6 fork (old K&R-ish C); `make compiler` passes the
needed `-w`/`-Wno-*`/`-std=gnu89` flags (`COMPILER_CF`) so it builds clean on a
modern host gcc. Builds on x86-64 and ARM64.

**Optimization: `-O1` only.** `-O2`/`-Os`/`-O3` are UNSAFE on this backend: at `-O2`+ the `-funit-at-a-time` DCE drops `static` tables whose address is held by a global pointer (`static t[]={..}; T *p=t;`) → dangling `=V`/`DC A(@V)` → IFOX RC=8; and `-Os` additionally **miscompiles the rexx parser** (loops → S322). `-O1` is validated correct (rexx370 TSTALLB 84/84, 0 ABEND). This — not the old "3.2.3 memory issues" note — is the real reason for "-O1 only".

## Testing

No host-side unit tests for the compiler. Validation is on MVS via the ecosystem:

- Build `ctest` (dedicated charset test) and run `jcl/runctest.jcl` — fast charset check (expect 0 failures).
- Build crent370 + rexx370 (mbt), run rexx370 `test/mvs/tstall.jcl` (TSTALLB) — full correctness (expect 84/84, 0 ABEND).

**as370** is validated by **byte-identity to IFOX00** over the 950-module ecosystem corpus (its own oracle) plus the end-to-end MVS link+run (ctest `CTESTH`, RC=0). Folding this into `as370/tests/` + CI is an open point — see [Goal & Roadmap](#goal--roadmap-open-points).

## Architecture

Standard GCC pipeline: C source → lexer/parser → RTL → optimization → assembler output. Output is EBCDIC, HLASM syntax, MVS calling conventions (`COPY PDPTOP` / `PDPPRLG` / `PDPEPIL`), crent370-compatible.

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

- Char constants and string literals map to **CP037**. String literals stay in the **host** charset in the STRING_CST and convert to EBCDIC at **output** time (`ASM_OUTPUT_ASCII`): printables → `C'..'` (converted by the ASCII→EBCDIC file transfer on upload), control/variant/`&` → `X'<MAP_OUTCHAR>'`. This keeps inline-asm templates readable in the `.s` (no `-fexec-charset`).
- Newline `\n` → **NEL `0x15`** — the mvslovers ecosystem newline, byte-identical to httpd `cp037_atoe`/`cp037_etoa` (mvsMF upload, HTTP output, UFS, z/OS USS). NOT pure CP037 LF `0x25` (which breaks HTTP CRLF: `etoa[0x25]=0x85`, not LF).
- `\x`/`\NNN` escapes are pre-imaged in `cppcharset.c` (via `MAP_INCHAR`) so the output pass round-trips them to the literal byte — binary string data (e.g. crent dataset-I/O flags) is preserved.
- A char has one runtime value whether it is a constant or sits in a string (`'\n' == "\n"[0]` at runtime). Note: a *directly indexed* const-array read (`"\n"[0]`) constant-folds to the **host** byte — inherent to the host-STRING_CST design, identical to v1.4. Real code reads strings at runtime via pointers (`src[i] == '\n'`), which is correct.

### Key preprocessor defines

`TARGET_PDPMAC`, `TARGET_EBCDIC`, `TARGET_HLASM`, `TARGET_MVS`, `I370_IFOX_COLUMNS`, `IN_GCC`, `HAVE_CONFIG_H`.

## Important Notes

- `cc370/gcc/c-parse.c` is generated from `c-parse.in`; a pre-generated parser / dummy Makefile rule avoids running yacc.
- Symbol names in address constants must be emitted via `output_addr_const` (not `ASM_OUTPUT_LABELREF` on the raw `XSTR`) so the leading `*` of an `asm()`-named extern is stripped — taking the **address** of an asm-named extern otherwise emits invalid `=V(*NAME)` → IFOX IFO161 (fixed in v2.0).
- Output uses EBCDIC encoding and HLASM syntax with MVS calling conventions.

## as370 — Host-Native MVS Assembler

`as370/src/as370.c` is a single-file (~1900 lines) host-native MVS **Assembler-XF (IFOX00)** clone: macro preprocessor + two-pass core + OS/360 OBJ writer (80-byte EBCDIC ESD/TXT/RLD/END cards). It runs on macOS/Linux and produces object decks **byte-identical to IFOX00**.

- **Identity:** tool name `as370`, product id `ASM370`, version `V1.0`. `as370 -v` → `as370 V1.0 - <build date>`.
- **Build:** `gcc -O2 -Wall -Wextra -Werror -Ias370/include -o as370/as370 as370/src/as370.c` (warning-clean under gcc-14 + clang).
- **CLI:** z/OS-`as`-aligned. `--help` usage; RC convention from IFOX `JERMSGCD` (0 clean / 4 warn / 8 error / 12 severe / 16 terminal); silent on success (no noise when called from cc370). Friendly per-statement diagnostic: prints the true source line + `ERROR: Undefined operation code in line N - op`.
- **Macro path:** `-I <dir>` (repeatable). The ecosystem needs crent370 `maclib` + `sysmac` and SYS1.MACLIB members.
- **Validation = byte-identity to IFOX00**, the authoritative oracle. 950 ecosystem modules reproduce exactly: crent370 736/736, rexx370 81/81, UFSD 20/20, HTTPD 105/105, 9 samples. The END card's translator IDR (`15741SC103`+date) is IFOX-specific and intentionally not reproduced; "byte-identical" means ESD/TXT/RLD content. The full patched IFOX source is the reference (NOT committed — IBM proprietary; see memory `ifox-source-reference`).
- **`-a` listing:** ASCII, column-exact to IFOX SYSPRINT for the ESD + SOURCE + RLD sections. Cross-reference / literal-xref / diagnostics / statistics pages not yet produced (see open points).

### cc370 → as370 integration (current: stopgap wrapper)

The GCC driver invokes an assembler literally named `as`, found in its own exec dir before PATH. A shell wrapper at `~/.local/libexec/gcc/i370-ibm-mvspdp/3.4.6/as` execs `as370` with the macro `-I` paths, so `cc370 -c x.c` runs cc1 → temp `.s` → as370 → `x.o`. **This is a stopgap:** the crent370 macro path is hardcoded in the wrapper and `/tmp/sys1mac` is ephemeral. The clean design (a real `as1` engine shared by standalone `as370` and the driver, with the macro path passed properly) is an open point.

## Goal & Roadmap (Open Points)

**Goal:** a fully host-native MVS cross-toolchain — compile (cc370) + assemble (as370) + **link (ld, planned)** on the host, so only the final load module touches MVS. Today cc370+as370 are proven end-to-end (ctest links + runs on MVS, RC=0); `ld` is the missing piece.

**as370 remaining work:**
- **More listing options** — `-a` sub-letters (g/i/m/s/x) are no-ops/provisional; add the CROSS-REFERENCE, LITERAL XREF, DIAGNOSTICS, STATISTICS pages.
- **Better driver / cc370 integration** — replace the stopgap shell wrapper with a proper `as370`/`as1` split; stop hardcoding the crent370 macro path; give SYS1.MACLIB + crent maclib/sysmac a permanent, configurable home (the `/tmp/sys1mac` dependency must go).
- **Assembler options from IFOX00 sources** — derive the real `PARM=` option set + RC/severity semantics from the IFOX source (`~/repos/mvs/ifox-src/all/`).

**cc370 / packaging work:**
- **Done:** carved into its own `mvslovers/cc370` repo (this one); the top-level `Makefile` builds the driver as **`cc370`** and installs as370/ld370/ar370 as ordinary tools; `c2asm370` v1.x is frozen as the fallback.
- **cc370 cosmetics** — banners say `cc370 V1.0`; still open: the doubled `cpu`/`machine` `#assert` warnings (`cc370/gcc/config/i370/mvspdp.h:84-85` re-assert what `i370.h:34-35` already does → harmless "re-asserted" cpp warnings); align `-v`/`--help` wording with as370.

**Cross-cutting (additions):**
- **Host-side regression harness** — fold the 950-module IFOX byte-identity corpus check into `as370/tests/` + CI so codegen/assembler changes can't silently regress (today it's ad-hoc `/tmp` scripts).
- **mbt host-assembly backend** — teach mbt to assemble locally and upload OBJECT (skip the IFOX00 ASM step); after `ld`, upload only the load module.

**`ld370`** — a host-native MVS linker (replace IEWL) producing the load module on the host, **end-to-end proven on real MVS**. Links multiple OBJ decks into a member byte-identical to IEWL over the `ld370/tests/fixtures` oracles, wraps it into the IEBCOPY **unloaded-PDS** image (`--unload`, multi-member `--pack`), and wraps THAT into a **TSO TRANSMIT / NETDATA** file (`--xmit`, RECFM=FB80). FB80 uploads byte-clean via mvsMF (the bare unload is RECFM=VS, which mvsMF can't rebuild on upload), and **`RECV370`** installs it into a load library. **Validated 2026-06-19:** `as370→ld370→--xmit` built E2E with zero IFOX/IEWL/IEBCOPY, uploaded, RECV370-installed (`IEB154I`), and ran with **RC=7** — the project endgame (only the final load module touches MVS, via one RECV370 step). Formats: `docs/unload-format.md`, `docs/xmit-format.md`.

**Stage 3 — single-member multi-track DONE & validated on real MVS (2026-06-20):** device-agnostic *one block per track* geometry (each physical block alone on its relative track at R=1, CC/HH wrap at 30 trk/cyl, UDEBX sized to span them). A multi-track single-member load module emitted via `--xmit`, uploaded FB80, RECV370-installed → reloads + runs (RC=7), no `IEB139I`.

**DEFERRED — multi-member packing (`--pack`: several load modules bundled into ONE `--unload`/`--xmit`).** The one-block-per-track layout places each member's `DL=0` EOF alone on its own track, but a real IEBCOPY unload packs members **contiguously** (the next member continues the R-sequence on the same track; the EOF is just the next record, not on its own track). So RECV370's member-loop reads past the last member and abends (`U0200-09 RECV370 .RECVCTL` / `IEB183I END OF FILE READ ON LOAD DATA SET`). **Single-member (one program = one member) is the practical case and works** — multi-member libraries are parked here. When we pick this up: the fix is contiguous member packing like the XFASM oracle (full diagnosis in the `ld-design-decisions` memory).

Still open (Stage 3): compute INMSIZE/source-DCB + PDS2 user-data for arbitrary members; an mbt host-link backend that ships the XMIT instead of submitting ASM/LINK JCL.

**Automatic library call (done):** `ar370` (`ar370/src/ar370.c`) archives object decks into a `.a` with an ESD symbol index; `ld370 -l/-L` autocalls against it (fixpoint, validated == explicit link on toys, and **proven to pull the real crent370 runtime closure**: `@@CRT0→@@START→…→FOPEN/PUTS/SPRINTF`).

**Linking real cc370 programs (in progress, the path to "a C program runs"):** pulling the crent closure surfaced what ld370 still needs beyond toy modules. (A) **Blank PC sections must be per-object** — cc370 emits each module as an unnamed private-code (PC) section; ld370 interned sections by name, collapsing every crent module into one. (B) **References to LD entries must relocate** — cc370 functions are LD entries inside the PC section and cross-calls are V-cons to them; ld370 only relocated section (SD) targets, leaving them "unresolved." Then: (C) **configurable entry point** — ld370 needs `-e/--entry NAME` (project.toml sets `entry="@@CRT0"` per module; **some httpd/mvsMF modules use a non-crt0 entry**, so cc370 also needs a `-nostartfiles`-style option to skip the `@@MAIN→@@CRT0` stub — don't forget this); (D) **CM (common)** for C globals; (E) **record splitting for large modules** — **pt.1 DONE**: text emitted as multiple control+text records ≤ MAXTEXT (18432), and emit_xmit packs member data into ≤MAXTEXT NETDATA records (both overflowed RECV370's RECVBLK before); **pt.2 OPEN**: a real C program's member is ~69KB > one ~56KB track, but all CKD records still claim CC=0x8d/HH=0 → RECV370's physical reload to SYSUT1 fails (`IEB139I` I/O error in RECVCTL). Needs per-track HH/CC assignment (e.g. one block per track) + UDEBX sizing; no RECV370 source, so reverse-engineer via MVS experiments. Capacity (MAXOBJ/MAXG/buffers) already raised. The cc370→as370→ld370(+autocall)→XMIT chain otherwise links a real C program (t1 = `int main(){return 7;}` against full crent370 `libcrent.a`): 141 sections, refs resolved, entry=8, modlen=58600, text split into 4 records — only the track geometry remains before it runs.

## User Preferences

- **No Claude references:** Never add `Co-Authored-By: Claude` lines to commits, and never mention Claude Code in code comments or commit messages.

# Development Workflow

## Bugfix Workflow

1. **Branch erstellen**: `fix/<beschreibung>` von `main`, z.B. `fix/sprintf-null-pointer`

### Phase 1: Analyse & Planung (Opus 4.6)

1. **Bug reproduzieren**: Wenn möglich, erst einen Testfall oder ein Minimalbeispiel erstellen, das den Bug zeigt
2. **Ursache analysieren**: Code lesen, Zusammenhänge verstehen, Root Cause identifizieren
3. **Fix planen**: Lösungsansatz erarbeiten und mit dem User abstimmen

### Phase 2: Implementierung (Sonnet 4.6)

1. **Fix implementieren**: Geplanten Fix umsetzen
2. **Testen**: Sicherstellen, dass der Fix funktioniert und nichts anderes bricht
3. **Commit**: Conventional Commits Format: `fix: <kurze Beschreibung>`
   - Body optional mit Ursache/Kontext, wenn nicht offensichtlich
4. **Merge**: Branch in `main` mergen

### Phase 3: Abschluss

1. **Issue kommentieren & schließen**: Kurzen Kommentar im Issue hinterlassen mit:
   - Was war das Problem (Root Cause)
   - Wie wurde es behoben (Lösung)
   - Keine AI/Claude-Referenzen

### Modellwechsel

- Phase 1 (Analyse/Planung): immer **Opus 4.6**
- Phase 2 (Codierung): **Sonnet 4.6**
- Bei Problemen während der Implementierung: auf Nachfrage zurück zu Opus 4.6

## Conventions

- Keine AI/Claude-Referenzen in Commits, Kommentaren oder Code
- Commit-Messages auf Englisch
