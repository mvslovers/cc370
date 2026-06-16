# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

c2asm370 compiles C source to IBM System/370 HLASM assembler (`.s` files) for MVS 3.8j. It is a **cross-compiler**: it runs on the host (macOS/Linux) and emits mainframe assembler; it does **not** produce object files — the `.s` is uploaded to an IBM assembler (IFOX00) on the target.

**Two generations live in this repo:**
- **`main` — v1.x:** GCC **3.2.3** fork (the original c2asm370).
- **`V2.0.0` — v2.0:** GCC **3.4.6** for the `i370-ibm-mvspdp` target (`TARGET_PDPMAC`), slimmed to the i370 target. Imported from the `i370-gcc` fork. **Active work is on v2.0.** See `V2.0.0-README.md` for provenance.

The rest of this file describes **v2.0** (the `V2.0.0` branch).

## Build (v2.0 — C-only cross-compiler, modern macOS/Linux host)

GCC 3.4.6 is old K&R-ish C; modern clang/gcc must be told not to error on it:

```sh
CF="-g -O0 -fcommon -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration \
    -Wno-int-conversion -Wno-error -Wno-return-type -Wno-deprecated-non-prototype"
mkdir build && cd build
CFLAGS="$CF" CFLAGS_FOR_BUILD="$CF" ../configure \
  --target=i370-ibm-mvspdp --enable-languages=c \
  --disable-threads --disable-nls --disable-shared --without-headers \
  --with-gcc-version-trigger=../gcc/version.c
make all-gcc CFLAGS="$CF" CFLAGS_FOR_BUILD="$CF"
```

Produces `build/gcc/cc1` (compiler proper) and `build/gcc/xgcc` (driver). Install: `cc1` → `~/.local/libexec/gcc/i370-ibm-mvspdp/3.4.6/cc1`, driver → `~/.local/bin/i370-ibm-mvspdp-gcc` (the `c2asm370` symlink points at the driver). Builds on x86-64 and ARM64.

**Optimization: `-O1` only.** `-O2`/`-Os`/`-O3` are UNSAFE on this backend: at `-O2`+ the `-funit-at-a-time` DCE drops `static` tables whose address is held by a global pointer (`static t[]={..}; T *p=t;`) → dangling `=V`/`DC A(@V)` → IFOX RC=8; and `-Os` additionally **miscompiles the rexx parser** (loops → S322). `-O1` is validated correct (rexx370 TSTALLB 84/84, 0 ABEND). This — not the old "3.2.3 memory issues" note — is the real reason for "-O1 only".

## Testing

No host-side unit tests. Validation is on MVS via the ecosystem:

- Build `ctest` (dedicated charset test) and run `jcl/runctest.jcl` — fast charset check (expect 0 failures).
- Build crent370 + rexx370 (mbt), run rexx370 `test/mvs/tstall.jcl` (TSTALLB) — full correctness (expect 84/84, 0 ABEND).

## Architecture

Standard GCC pipeline: C source → lexer/parser → RTL → optimization → assembler output. Output is EBCDIC, HLASM syntax, MVS calling conventions (`COPY PDPTOP` / `PDPPRLG` / `PDPEPIL`), crent370-compatible.

### Key directories

- **`gcc/config/i370/`** — the i370/mvspdp target backend. **Check here first for codegen bugs.**
- **`gcc/`** — GCC 3.4.6 core (C frontend, RTL, optimization passes, `cppcharset.c` for escape/charset handling). Largely upstream.
- **`libiberty/`, `include/`** — GNU support library + shared internal headers.

Unlike v1.x (3.2.3), v2.0 does **not** shadow `toplev.c`/`varasm.c`/`final.c` in the target dir — the target is self-contained in `gcc/config/i370/`.

### gcc/config/i370 (primary modification area)

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

- `gcc/c-parse.c` is generated from `c-parse.in`; a pre-generated parser / dummy Makefile rule avoids running yacc.
- Symbol names in address constants must be emitted via `output_addr_const` (not `ASM_OUTPUT_LABELREF` on the raw `XSTR`) so the leading `*` of an `asm()`-named extern is stripped — taking the **address** of an asm-named extern otherwise emits invalid `=V(*NAME)` → IFOX IFO161 (fixed in v2.0).
- Output uses EBCDIC encoding and HLASM syntax with MVS calling conventions.

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
