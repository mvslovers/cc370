# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

c2asm370 is a stripped-down version of GCC 3.2.3 that compiles C source code to IBM System/370 HLASM assembler source files. It is a cross-compiler: it runs on Linux and produces mainframe assembler output (`.s` files). It does **not** produce object files — assembly must be uploaded to an IBM-compatible assembler on the target platform.

## Build Commands

```bash
make                              # Build the c2asm370 executable (32-bit Linux)
make clean                        # Remove object files and executable
make install                      # Install to $(PREFIX)/usr/local/bin
./c2asm370 -S test.c              # Compile a C file to assembler (produces test.s)
```

**Build requirements:** GCC with 32-bit support (`-m32`), GNU Make. Limited to `-O1` optimization due to memory management issues in the GCC 3.2.3 source.

## Testing

No automated test suite. Manual testing workflow:

1. `make` to build the compiler
2. `./c2asm370 -I pdpclib -S test.c` to compile the test program
3. Inspect the generated `test.s` against expected HLASM output

## Architecture

The compiler follows the standard GCC pipeline: C source → lexer/parser → AST → RTL → optimization → assembler output.

### Key Directories

- **`i370/`** — IBM 370 target-specific code. **Check here first for bugs or modifications.** Contains customized versions of GCC files (`toplev.c`, `final.c`, `varasm.c`) plus the machine definition (`i370.c`, `i370.h`).
- **`gcc/`** — Core GCC 3.2.3 compiler (C frontend, RTL generation, optimization passes). Largely unchanged from upstream.
- **`libiberty/`** — GNU support library (memory allocation, data structures, string utilities).
- **`include/`** — Shared header files for libiberty and GCC internals.
- **`macro/`** — HLASM macro definitions used by generated assembler output (prologue/epilogue, calling conventions, runtime support).

### i370 Directory (Primary Modification Area)

| File | Purpose |
|------|---------|
| `i370.c` | Machine definition — RTL-to-assembly instruction mapping |
| `i370.h` | Target machine constants and register definitions |
| `i370-c.c` | C frontend pragma handling |
| `final.c` | Final pass assembler output generation (customized from `gcc/final.c`) |
| `toplev.c` | Top-level compiler driver (customized from `gcc/toplev.c`) |
| `varasm.c` | Static/global variable assembly generation (customized from `gcc/varasm.c`) |

### Key Preprocessor Defines

`IN_GCC`, `HAVE_CONFIG_H`, `PUREISO`, `TARGET_MVS`, `HOST_LINUX`, `MVSGCC_CROSS` — defined in the Makefile's `CFLAGS`.

## Important Notes

- The `i370/` files shadow several `gcc/` files (`toplev.c`, `varasm.c`, `final.c`) with target-specific versions. Both exist in the build.
- Output uses EBCDIC character encoding and HLASM syntax with MVS calling conventions.
- The `gcc/c-parse.c` has a dummy Makefile rule to prevent yacc from running — it uses a pre-generated parser.

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
