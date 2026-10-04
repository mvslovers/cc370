# as370 — host-native MVS assembler

Part of the **cc370** host-native MVS cross-toolchain (cc370 / as370 / ld370 /
ar370). `as370` is an Assembler-XF (**IFOX00**) clone that runs on the host
(macOS/Linux) and emits OS/360 object decks directly — so the C→object path no
longer needs IFOX00 on MVS. Single C file (`as370.c`), no separate binutils.

## Status — done (the assembler matches its IFOX00 oracle)

`as370` reproduces IFOX00 **byte-for-byte** over the 950-module ecosystem corpus
(libc370 [formerly crent370] 736/736, rexx370 81/81, UFSD 20/20, HTTPD 105/105, 9 samples). Its
object decks link with IEWL and with the host-native **ld370**, and the result
runs on real MVS (the end-to-end `cc370 → as370 → ld370 → --xmit` chain ran a C
test program with the expected result). "Byte-identical" means the ESD/TXT/RLD
content; the END card's translator IDR is IFOX-specific and intentionally not
reproduced.

Build & validate:

```sh
gcc -O2 -Wall -Wextra -Werror -o as370 as370.c
sh ../ld370/tests/run.sh        # the ld370 regression also drives as370 over the fixtures
```

`as370 --version` (or `-v`) → `as370 1.0.0 (<commit>)`, the toolchain version
from `VERSION`; `as370 --help` for the CLI (z/OS-`as`
aligned). Macro search path via `-I dir` (repeatable: libc370 maclib + sysmac +
SYS1.MACLIB members).

## What it does

- **Two-pass core:** location counter, symbol table, module length; instruction
  formats RR/RX/RS/SI/SS + extended branches; directives CSECT (named SD /
  unnamed PC), ENTRY (LD), USING/DROP, DC/DS/EQU/LTORG/END, literal pool
  (`=V`/`=A`/`=F`) with LTORG placement.
- **Macro / conditional-assembly preprocessor** (expands to flat open code
  before the core): inline `MACRO`/`MEND` + library lookup + `COPY`; name /
  positional / keyword params, `&`-substitution (incl. in literals, `&x.`
  concatenation), nested expansion; `GBLx`/`LCLx`, `SETA`/`SETB`/`SETC`, `AIF`
  (logical/relational, `T'`/`N'`/`K'`/`L'`, substrings), `AGO`/`ANOP`/`MEXIT`,
  sequence symbols, sublist params, attribute-driven expansion — enough for the
  real SAVE/RETURN and the cc370 prologue/epilogue (`PDPTOP`/`PDPPRLG`/`PDPEPIL`).
- **OS/360 OBJ writer:** 80-byte EBCDIC ESD/TXT/RLD/END cards from one internal
  ESD/TXT/RLD model — PC/LD symbols, multi-card gap-aware TXT, RLD bit-7
  continuation packing — matching IFOX exactly.
- **`-a` listing:** ASCII, column-exact to IFOX SYSPRINT for the ESD/SOURCE/RLD
  sections and the CROSS-REFERENCE / LITERAL CROSS-REFERENCE pages (`-as`, and
  part of a bare `-a`). `--xref=short` gives XF's `XREF(SHORT)`, which leaves
  out the symbols nothing references. The pages are compared against every
  IFOX00 listing in `tests/listref` by `tests/listref/xref.py`.

## Source encoding

IFOX00 reads EBCDIC, one byte per character. as370 reads a host file and keeps
that rule by deciding the encoding **per file** (source and every library
member):

- A file that is valid **UTF-8** and holds a byte above `X'7F'` is decoded to one
  byte per character, so columns (72 = continuation) and constant lengths count
  characters. A leading byte order mark is dropped.
- Anything else — ASCII, or **Latin-1** such as the `¬` = `X'AC'` in many
  libc370 and MVSBLD macros — is read byte for byte, as before.
- Each character is then translated Latin-1 → CP037 (`¬` → `X'5F'`, `¢` →
  `X'4A'`).
- A character above U+00FF has no CP037 image. It is read as `X'3F'` (SUB) and
  its card is flagged at **severity 4**; if it reaches object code (a `C`
  constant, a `C'…'` self-defining term, a `REPRO` card) the statement is
  flagged at **severity 8**. The flagged statement shows it as `?`.

What as370 writes back as text (`-e`, the `-a` listing) is in that one-byte
form, i.e. Latin-1 for a decoded UTF-8 source. See mvslovers/cc370#483.

## Open points

- More `-a` listing pages (DIAGNOSTICS, STATISTICS) — currently not produced.
- A cleaner driver integration: replace the stopgap `as` shell wrapper that
  cc370 invokes (which hardcodes the crent370 macro path and the ephemeral
  `/tmp/sys1mac`) with a proper split + a permanent, configurable macro home.
- Derive the real `PARM=` option set + RC/severity semantics from the IFOX00
  source.

See `../internals/object-module-format.md` for the OBJ format as370 emits, and
`../internals/roadmap-integration.md` for the whole-suite roadmap.
