# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

cc370 compiles C source to IBM System/370 HLASM assembler (`.s` files) for MVS 3.8j. It is a **cross-compiler**: it runs on the host (macOS/Linux) and emits mainframe assembler.

**The goal (v2.0): a fully host-native MVS cross-toolchain.** Historically the `.s` was uploaded to the IBM assembler (**IFOX00**) on the target. v2.0 adds **`as370`** (`as370/src/as370.c`) — a host-native MVS Assembler-XF clone that produces OS/360 object decks **on the host**, byte-identical to IFOX00. The endgame is to compile, assemble, **and link** on the host so the only thing that touches MVS is the final load module (eventually nothing). Components:

| Tool | Role | Status |
|------|------|--------|
| **cc370** | C → i370 HLASM `.s` (the GCC 3.4.6 fork; `cc370/gcc/`) | works; `-O1` only |
| **as370** | `.s`/`.asm` → OS/360 OBJ deck (`as370/src/as370.c`) | **byte-identical to IFOX00 (950 modules); links + runs on MVS** |
| **ld370** | OBJ decks → MVS load module (replace IEWL) + automatic library call (`-l`/`-L` over `.a`) + `-iebcopy`/`-xmit` host→MVS transport (`ld370/src/ld370.c`) | member byte-identical to IEWL; `-iebcopy`/`-xmit` byte-identical to their oracles (XMIT modulo timestamp); autocall validated (single + transitive pull == explicit link). **End-to-end on real MVS: `as370→ld370→-xmit` → upload → RECV370 → runs, RC=7 (Stage 2 done)** |
| **ar370** | OBJ decks → `.a` archive + ESD symbol index (`ar370/src/ar370.c`) | standard `ar` container (host-inspectable) with a GNU `/`-member symbol table built from each deck's ESD (variable-length names, long-symbol-ready); the static-library ld370 autocalls against |
| **file370** | identify + analyze any toolchain format (`file370/src/file370.c`) | read-only `file`/`objdump` inspector: sniffs OBJ deck / `.a` / load module / `-iebcopy` unload / `-xmit` NETDATA from leading bytes; one-line summary (default) or `-v` structural dump (ESD / records / directory / INMR text units — peels the XMIT→unload→member onion). Standalone (not driven by cc370). |

**End-to-end validated on real MVS (2026-06-18):** `cc370 → as370` built ctest locally (no IFOX00), the decks linked with IEWL (RC=0) and ran (`PGM=CTESTH`) with **RC=0** (all charset checks pass). See `as370/` and the [as370 section](#as370--host-native-mvs-assembler).

**This repo is the v2.0 toolchain:** GCC **3.4.6** for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`), slimmed to the i370 target, plus as370/ld370/ar370. Imported from the `i370-gcc` fork (snapshot of `mvslovers/i370-gcc` @ `0710af0c`; see README "Provenance"). The earlier GCC **3.2.3**-based **c2asm370 v1.x** lives in the frozen `mvslovers/c2asm370` repo (kept as a fallback so existing ecosystem projects keep building against the old name); the matching v1.x libc is the frozen `crent370`. The current libc is `mvslovers/libc370`.

## Build (v2.0 — C-only cross-compiler, modern macOS/Linux host)

The top-level `Makefile` drives everything. The toolchain is **one driver
(`cc370`) plus four standalone tools (`as370`/`ld370`/`ar370`/`file370`)**:

```sh
make            # build the WHOLE toolchain: cc370 + as370/ld370/ar370/file370
make tools      # only the four standalone tools   [fast]
make compiler   # configure + build the driver (cc370) and cc1   [slow]
make install    # build (if needed) + install into $(PREFIX) (default ~/.local)
```

Install layout (clean cc370-branded, under `$(PREFIX)`): everything for the target
lives in one `cc370/` tree; only the user-facing binaries sit on PATH.

- `bin/cc370` — the driver (the *only* driver). `bin/{as370,ld370,ar370,file370}`
  are symlinks → `../cc370/bin/*` for PATH access.
- `libexec/cc370/1.0.0/cc1` — the driver-private compiler proper; beside it,
  `{as,ld,ar}` symlinks → `../../../cc370/bin/*` are the driver's **tooldir** (it
  looks up `as`/`ld`/`ar` there by short name). `file370` is *not* here — the
  driver never invokes it (it is a standalone inspector, PATH-link only).
- `cc370/bin/{as370,ld370,ar370,file370}` — the **real** tool binaries.
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

**Output format (`-flinker-output=`).** `cc370 foo.c -o app` writes a load-module
member (LMOD). `-flinker-output=xmit` *additionally* emits `app.xmit` (TSO
TRANSMIT/NETDATA); `=iebcopy` emits `app.iebcopy` (IEBCOPY unloaded PDS). It is flag-
driven, not -o-extension-driven. Mechanism: `flinker-output=` is registered in
`gcc/common.opt` (`Common Joined`) with a no-op `case OPT_flinker_output_` in
`gcc/opts.c` (else `common_handle_option`'s `default: abort()` ICEs); `LINK_SPEC`
(`mvspdp.h`) maps the value to ld370's `-xmit`/`-iebcopy` via
`%{flinker-output=xmit:-xmit}`. ld370 itself is flag-driven too: `-o OUT` =
member, `-xmit`/`-iebcopy` (no-arg) add `OUT.xmit`/`OUT.iebcopy`.

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

**`ld370`** — a host-native MVS linker (replace IEWL) producing the load module on the host, **end-to-end proven on real MVS**. Links multiple OBJ decks into a member byte-identical to IEWL over the `ld370/tests/fixtures` oracles, wraps it into the IEBCOPY **unloaded-PDS** image (`-iebcopy`, multi-member `--pack`), and wraps THAT into a **TSO TRANSMIT / NETDATA** file (`-xmit`, RECFM=FB80). FB80 uploads byte-clean via mvsMF (the bare unload is RECFM=VS, which mvsMF can't rebuild on upload), and **`RECV370`** installs it into a load library. **Validated 2026-06-19:** `as370→ld370→-xmit` built E2E with zero IFOX/IEWL/IEBCOPY, uploaded, RECV370-installed (`IEB154I`), and ran with **RC=7** — the project endgame (only the final load module touches MVS, via one RECV370 step). Formats: `docs/unload-format.md`, `docs/xmit-format.md`.

**Stage 3 — single-member multi-track DONE & validated on real MVS (2026-06-20):** device-agnostic *one block per track* geometry (each physical block alone on its relative track at R=1, CC/HH wrap at 30 trk/cyl, UDEBX sized to span them). A multi-track single-member load module emitted via `-xmit`, uploaded FB80, RECV370-installed → reloads + runs (RC=7), no `IEB139I`.

**Multi-member packing (`--pack`: several load modules in ONE `-iebcopy`/`-xmit`) — DONE & validated on real MVS (2026-06-22).** The operative fix was the **XMIT transport framing**, not the unload geometry: `emit_xmit` packed all members' data into one NETDATA logical record → one RECFM=VS record in SYSUT1, and IEBCOPY LOAD (which reads SYSUT1 one VS record at a time) lost every member packed *behind* an earlier member's `DL=0` EOF → `IEB183I`/`U0200-09 RECV370 .RECVCTL`. Fix: end the logical record at each per-member EOF (each member its own VS record); single-member XMIT is byte-identical (its only EOF is the trailing EOM). `emit_unload` also now packs members **contiguously** (R continuous along the track, EOF = next record, dir TTR/`PDS2TTRT` carry the real R) to match a real IEBCOPY UNLOAD oracle (`tests/fixtures/e2e2.iebcopy-unload.bin`) — kept as oracle-faithful, but not isolated as strictly necessary. **Validated:** `--pack E2EA+E2EB → -xmit → RECV370` installs both (`IEB154I` ×2, RC=0) and each runs (RUNA=0007, RUNB=0003). Guard: `tests/xmit_check.py` asserts per-member VS framing (the host *unload* simulator cannot see XMIT framing). **Multi-block directory — DONE & validated on MVS (2026-06-23):** >6 members spill into multiple 256-byte directory blocks (a single fixed `dir[256]` overflowed at the 7th member → SIGABRT). `emit_unload` emits 7 name-sorted entries per non-last block + a final FF-terminator block (key = high name per block, FF on the last), each block its own VS record in the XMIT; matches the CBT571 XFASM oracle. Validated: 8 members (2 blocks) install (`IEB154I` ×8) and the spillover member in block 2 runs. **Still unvalidated:** a member whose data exceeds `MAXTEXT` (18432) spans multiple VS records with no EOF between them (same territory as the 69KB t1 case). Full trail in the `ld-design-decisions` memory.

**`--pack` PDS2 directory (modlen + entry) — DONE & validated on MVS (2026-06-22).** `--pack` used to write `modlen=-1`/`entry=-1` per member → `build_userdata` echoed the template (PDS2STOR=8, PDS2EPA=0), so every packed member showed **SIZE 8** on MVS and lost its entry point. `modlen` (PDS2STOR) is now recomputed from the member's CESD (`member_modlen()` = the single-link's `roundup8(running)`). The **entry point is NOT in a bare `.lm`** (the single-link path only ever writes it to the directory), so `--pack` also accepts **single-member `-iebcopy`** inputs (the self-describing form), recovering the real entry + modlen from their directory (`read_iebcopy_member()`). Recommended workflow: build each module `ld370 -o NAME --name NAME obj... -iebcopy`, then `ld370 --pack A=A.iebcopy B=B.iebcopy -o lib -xmit`. Bare `.lm` inputs still work (modlen recomputed; entry assumed 0). Validated: AMBLIST shows BIGENT `MAIN ENTRY POINT 0003E8` and it runs RC=7 (a wrong entry 0 would abend on the filler); packed single-member directory is byte-identical to the single-link `-iebcopy` directory.

**`--pack` carries the WHOLE PDS2 directory entry, not just entry+modlen (2026-06-23).** Same bug class, wider: `build_userdata` also templated the APF **AC** (PDSAPFAC, from the global `apfcode`=0) and the **RENT/REUS/REFR/...** attributes (PDS2ATR1/2) — none of which are in a bare member's records. For `-iebcopy` inputs, `read_iebcopy_member()` now captures the full 24-byte user-data into `umember.src_ud` and `build_userdata()` keeps it verbatim, re-stamping only the position-dependent `PDS2TTRT`. So entry, modlen, AC and all attributes survive `--pack` (incl. mixed ACs across members). Validated on MVS via `IEHLIST LISTPDS FORMAT`: FTPD (`--ac 1`) → `AUTH=YES`, SSIR (`--ac 0`) → `AUTH=NO` (`run_pack_ac_mvs.py`); host guard: `run.sh` `nzent` is now linked `--ac 1` so the byte-identity check covers AC too. `file370 -v` decodes these attributes (`[RENT REUS EXEC 1BLK NRLD AC=1]`).

**`--norent` / `--noreus` — clear the RENT/REUS attributes (2026-06-24).** The template marks every linked module RENT+REUS (`PDS2ATR1` 0xC0); a REXX370 module with modifiable storage must not be RENT. `--norent` clears `PDS2RENT` (0x80), `--noreus` clears `PDS2REUS` (0x40); RENT implies REUS so `--norent` alone leaves a serially-reusable module, both clear it entirely. Applied at the build/link path (like `--ac`); a `--pack` of a `-iebcopy` member keeps its OWN attributes (set at its build), so per-member RENT/REUS mix in one library. `run.sh` checks ATR1 = C3/43/83/03 for default/`--norent`/`--noreus`/both + pack-preservation.

**Dropped-text / S106-0F on FETCH of large modules — FIXED (2026-06-24).** A large ld370-linked module (REXX370 `IRX#HELO`) abended **S106 reason 0F** in program fetch before running. Two corrections to the bug report: (1) **0F = `RCIOERR` "permanent I/O error", NOT "invalid record"** (`IEWFETCH.ASM:238`; bad-record is 0D, bad-addr 0E) — so fetch couldn't physically read the member, the records weren't malformed. (2) ld370 was **silently dropping ~241 KB of text.** The control+text packer walked sections in **gid order** (G[] creation ≈ ESDID order) but the greedy chunker *assumed increasing-origin order*. `ISTSO` is referenced early (low gid) but **defined in the LAST linked object** (`asm/istso.asm`) → low gid, near-highest origin (248944); at that out-of-order section `origin − chunkstart > MAXTEXT`, so the packer closed the chunk early and **skipped every section between** (19 sections incl. 66 KB/41 KB/38 KB CSECTs). The half-loaded module looked self-consistent but couldn't be fetched. IRXDBG worked only because its gid order == origin order. **Fix:** `gidx` (the packer's index, used ONLY there) is now **origin-sorted** instead of gid→G[], and the ID/length list emits each section's true `G[gi].gid`; byte-identical when gid order already equals origin order (suite green). Validated: synthetic early-ref/late-def reproducer drops 20 KB pre-fix / complete post-fix; real IRX#HELO objects now emit text == modlen, no hole (was 241 KB gap); `run.sh` `dropped-text` test. **CONFIRMED on MVS: IRX#HELO + IRXINIT run after the user's clean rebuild + redeploy.**

**Over-packed unload tracks / S106-0F on FETCH of small RLD modules — FIXED & MVS-CONFIRMED (2026-06-24).** A SECOND, independent S106-0F cause, found after IRX#HELO worked: the tiny REXX370 parameter modules (IRXTSPRM/IRXISPRM/IRXPARMS — pure data + internal A-cons, single text block + RLD) abended S106-0F on FETCH after the multi-member deploy, while a single-member deploy of the **byte-identical** member fetched fine and IEWL's own copy fetched fine. Key proof: **all 12 ld370 members are byte-for-byte identical to the IEWL reference** (so the dropped-text fix is perfect and the member content is correct), and a single-member deploy of IRXTSPRM ran (S0C1 = fetched then ran the data) while the 12-member pack S106'd. Root cause: `emit_unload`'s contiguous packing decided "track full" by BLKSIZE (15040) + a 12-byte per-record overhead (the unload count field), but a real 3350 track holds **19069** bytes with **~185** B/record gap+count overhead. Tracks with many small records claimed 50+ records / up to 24901 "real" bytes on a 19069 B track — physically-impossible CKD geometry. **mvsMF/BPAM still read such a member** (directory-driven, lenient) — which is why the bytes round-tripped and misled the diagnosis — but program FETCH's EXCP channel program, which positions by each record's on-disk count field, rejected it (RCIOERR). Big modules (few large records/track), single-member packs (one block/track) and the `e2e2` oracle (~12 records/track) never over-pack. **Fix:** `#define TRK_CAP_3350 19069` / `TRK_OVH_3350 185`; drive the track-full decision from real 3350 geometry (185 + data per record), not BLKSIZE/12+data. Only the track-boundary accounting changes — member bytes + directory are identical, so **redeploy (no recompile/relink) picks it up**. After: 0 tracks over capacity (was 10), max 46 records/track. **MVS-confirmed end-to-end** (deploy all 12 + EXEC PGM): IRXTSPRM/IRXPARMS now S0C1 (fetch OK) instead of S106; IRXDBG still RC=0.

**Target BLKSIZE is runtime — `--blocksize`, default 15040 (2026-06-24).** The unloaded form's BLKSIZE was a hardcoded `19069` (a 3350 full track). A member built at 19069 only fits a *fresh* `>=19069` library; **15040** is the de-facto LINKLIB blocksize, so a member built there installs into ANY LINKLIB with BLKSIZE `>=15040`. `--blocksize N` (default 15040, range 1024..32760) now drives, consistently: the text-record split limit `maxtext`, the unloaded-PS BLKSIZE `UNLOAD_BLKSIZE` (= N+20), the COPYR1 `UBLKSIZE` (off 6 = the library BLKSIZE) and `off 14` (= the PS BLKSIZE), and the INMR02 `INMBLKSZ` (#1 = N, #2 = N+20). `maxtext` is the largest IEWL `TXTSIZE` table entry `<= N` (HEWLFINT `TXT18K..TXT1K`; 15040→13312, 19069→18432), keyed off the *library* BLKSIZE not the device max, so a library smaller than the device track still yields blocks that fit it. **Field mapping pinned empirically** against two real oracles — `e2e` (3350/19069) and CBT571 `LOADLIB` (3380/6144): COPYR1 off 6 == IEBCOPY `INMR02#1` `INMBLKSZ`, off 14 == INMCOPY `INMR02#2` `INMBLKSZ` (off 14 was a latent skew — baked 19069 but its own INMR02#2 declared MINBLK). **Pack-time guard:** `--pack` does not re-split (`split_member` reproduces *build-time* block sizes), so packing a member built at a larger `--blocksize` while declaring a smaller one is **refused on the host** (`member '…' has a N-byte block > --blocksize M`) — and since mbt's SHA256 stamps skip rebuilding unchanged `.c`, a stale large-block member is the likely first-deploy state. Tests: `run.sh` `--blocksize` (COPYR1 off6/off14 + max block + INMR02#1, default 15040 + 19069 + 6144 overrides) and the guard negative control. **Host-validated only** — the BLKSIZE/SB37 class needs the user's `mbt deploy` (RECEIVE self-alloc); RECV370 round-trips use the JCL SYSUT2 DCB and bypass INMR02/COPYR1.

Still open (Stage 3): an mbt host-link backend that ships the XMIT instead of submitting ASM/LINK JCL. (INMSIZE — `8a4f42c` — and the source-DCB/BLKSIZE — this change — are now computed, no longer fixed E2E constants.)

**Automatic library call (done):** `ar370` (`ar370/src/ar370.c`) archives object decks into a `.a` with an ESD symbol index; `ld370 -l/-L` autocalls against it (fixpoint, validated == explicit link on toys, and **proven to pull the real crent370 runtime closure**: `@@CRT0→@@START→…→FOPEN/PUTS/SPRINTF`).

**Linking real cc370 programs (in progress, the path to "a C program runs"):** pulling the crent closure surfaced what ld370 still needs beyond toy modules. (A) **Blank PC sections must be per-object** — cc370 emits each module as an unnamed private-code (PC) section; ld370 interned sections by name, collapsing every crent module into one. (B) **References to LD entries must relocate** — cc370 functions are LD entries inside the PC section and cross-calls are V-cons to them; ld370 only relocated section (SD) targets, leaving them "unresolved." Then: (C) **configurable entry point** — ld370 needs `-e/--entry NAME` (project.toml sets `entry="@@CRT0"` per module; **some httpd/mvsMF modules use a non-crt0 entry**, so cc370 also needs a `-nostartfiles`-style option to skip the `@@MAIN→@@CRT0` stub — don't forget this); (D) **CM (common)** for C globals; (E) **record splitting for large modules** — **pt.1 DONE**: text emitted as multiple control+text records ≤ MAXTEXT (then a fixed 18432, now runtime `pick_maxtext(--blocksize)`, default 13312), and emit_xmit packs member data into ≤MAXTEXT NETDATA records (both overflowed RECV370's RECVBLK before); **pt.2 OPEN**: a real C program's member is ~69KB > one ~56KB track, but all CKD records still claim CC=0x8d/HH=0 → RECV370's physical reload to SYSUT1 fails (`IEB139I` I/O error in RECVCTL). Needs per-track HH/CC assignment (e.g. one block per track) + UDEBX sizing; no RECV370 source, so reverse-engineer via MVS experiments. Capacity (MAXOBJ/MAXG/buffers) already raised. The cc370→as370→ld370(+autocall)→XMIT chain otherwise links a real C program (t1 = `int main(){return 7;}` against full crent370 `libcrent.a`): 141 sections, refs resolved, entry=8, modlen=58600, text split into 4 records — only the track geometry remains before it runs.

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
