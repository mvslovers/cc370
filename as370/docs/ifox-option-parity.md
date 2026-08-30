# as370 against IFOX00 — option parity, and what the byte-identity claim covers

Companion to `docs/ld370-iewl-divergences.md`, same purpose: the reference
material that has no other owner. The **defects** live in the tracker.

## What "byte-identical to IFOX00" does and does not prove

as370's object decks reproduce IFOX00's exactly over the ecosystem corpus — 950
modules at the time the claim was first made, 743 libc370 modules in today's
gate. The END-card translator IDR is IFOX-specific and intentionally not
reproduced; "byte-identical" means ESD/TXT/RLD content.

That is strong evidence **for the constructs those modules contain, and no
evidence at all for the ones they do not.** A byte-identity comparison cannot
detect a construct missing from both sides of the diff, because the corpus never
uses it. Two of the defects fixed in 2026-08 were exactly that: DC/DS types
`P Z E L S Q` assembling to zero bytes with RC 0 (#53), and `CXD` sitting in the
`note_unknown` skip list so it was not even flagged. A survey of 1582
`.s`/`.asm`/`.mac` files across the ecosystem found zero occurrences of either.

Two gates exist and they answer different questions. `as370/tests/corpus`
(#48) is **differential** — it assembles the libc370 corpus with the working-tree
as370 and with a baseline as370 and reports which decks moved; it cannot tell you
as370 was already wrong, because both sides are as370. `tests/run.sh` and
`tests/listref` carry real IFOX00 oracles — nine reference decks and four
SYSPRINT listings — and those answer "is as370 right", for nine modules.
Extending the oracle half to the corpus is
[#23](https://github.com/mvslovers/cc370/issues/23).

## Options, against IFOX00's PARMTAB

Reference: `PARMTAB` in `ifox0d.asm:673-800`, terminated by `PARMEND` — roughly
50 entries counting the `NO...` forms, scanned by `SCAN30`/`SCAN40`
(`ifox0d.asm:219-228`), which EXecutes one instruction per matched entry.

**IFOX00:** `DECK/NODECK`, `OBJECT/OBJ` (+`NO`), `XREF/NOXREF`, `ESD/NOESD`,
`RLD/NORLD`, `RENT/NORENT`, `ALIGN/NOALIGN`, `TERM/TERMINAL` (+`NO`),
`NUM/NUMBER` (+`NO`), `STMT/NOSTMT`, `TEST/NOTEST`, `MCALL/NOMCALL`,
`ALOGIC/NOALOGIC`, `MLOGIC/NOMLOGIC`, `LIBMAC/NOLIBMAC`, `SYSMAC/NOSYSMAC`,
`YFLAG/NOYFLAG`, `LIST/NOLIST`, `BUF/BUFSIZE`, `FLAG`, `LINECOUNT/LC/LINECNT`,
`SYSPARM`, `LOAD/NOLOAD`, `ALGN/NOALGN`, `CALLS/NOCALLS`, `MINBUF/NOMINBUF`,
`MSGLEVEL`, `WORKSIZE`.

**as370:** `-o`, `-I`, `-a[egimrsx][=FILE]`, `-v`, `--help`, plus `-m` and `-d`
(accepted, no effect) and `--` (no-op). Of the `-a` sub-options only `e` (ESD) and
`r` (RLD) produce output; `g/i/m/s/x` are accepted and ignored, which the
`--help` text states honestly. The missing listing pages — cross-reference,
literal xref, diagnostics, statistics — are the `-a` half of the roadmap in
`CLAUDE.md`.

as370 is a declared subset, so most absences are not defects. Three items are
worth naming:

- **Unknown options are not rejected.** The argument loop ends in
  `else src = argv[ai];`, so any unrecognised argument becomes the source
  filename. That is a correctness bug, not a missing feature, and is filed as
  [#104](https://github.com/mvslovers/cc370/issues/104).
- **`SYSPARM`** is implemented neither as an option nor as the variable symbol
  `&SYSPARM`. #104 has the measured consequence — conditional assembly keyed on
  `&SYSPARM` silently takes the wrong branch. Whether as370 needs it at all
  depends on whether any target source uses it; one grep of the corpus before
  committing effort.
- **`YFLAG`** flags Y-type address constants, which hold two bytes and can
  silently truncate an address above 64 K. as370 **does** emit Y-cons (`Y` shares
  the 2-byte branch with `H`) and performs no range check. Unfiled; the same
  silent-truncation shape as the rest of this class.

**Present in IFOX00, absent in as370, no known consequence** — `FLAG`,
`MSGLEVEL`, `ALIGN`/`ALGN`, `LINECNT`/`LINECOUNT`/`LC`, `BUF`/`BUFSIZE`,
`MINBUF`, `WORKSIZE`, `MCALL`/`CALLS`, `ALOGIC`, `MLOGIC`, `LIBMAC`, `SYSMAC`,
`NUM`, `STMT`, `TEST`, `DECK`/`LOAD`/`OBJECT` (as370 uses `-o`). `RENT` is worth
one thought: in IFOX00 it triggers a *reentrancy check* that flags store-into-code,
which as370 does not perform — unrelated to `ld370 --norent`, which sets a module
attribute.

### `PRINT` / `NOPRINT`

Two different things share the name, and neither is a defect here.

**In HLASM/IFOX00, `PRINT` is an assembler statement**, not a PARM option —
`PRINT ON/OFF/GEN/NOGEN/DATA/NODATA`, controlling listing verbosity. as370 has it
in the `note_unknown` skip list, so it is accepted without a diagnostic, but it is
**not honoured**: a statement between `PRINT OFF` and `PRINT ON` still appears in
the `-a` listing. Purely cosmetic — no effect on the object deck. Correct to skip;
worth honouring only if listing fidelity ever matters.

**In IEWL, `PRINT`/`NOPRINT` are documented PARM options that its own source does
not implement** — see `docs/ld370-iewl-divergences.md`. Not an as370 concern, but
the cautionary note applies to both codebases: in these sources the prose and the
code can disagree, so verify against the option table.

## Reference sources

**IFOX00 assembler source** — `~/repos/mvs/ifox-src/`, ~15 MB of HLASM, 39
modules. Not in this repository and not to be committed to it. Module map, from
each file's `JHEAD`:

| module | lines | role |
|---|---|---|
| `ifnx1a.asm` | 5289 | edit phase (statement parsing) |
| `ifnx3a.asm` | 2721 | macro generator |
| `ifnx5a.asm` | 1513 | assembler opcode processor — DC/DS/DXD/CXD/LTORG, `RLDOUT` |
| `ifnx5m.asm` | 1677 | machine instruction processor (encoding) |
| `ifnx5d.asm` | 1370 | DC evaluation |
| `ifnx5f.asm` | 637 | DC fixed/floating point conversion |
| `ifnx5p.asm` | 738 | print + `PUNRTN`, the object-deck punch |
| `ifnx6a.asm` | 1578 | post processor |
| `ifox0d.asm` | — | `PARMTAB` + the option scanner |
| `jermsgcd.asm`, `erms.asm` | — | message numbers and severities |

**Grep caveat.** These sources are macro-driven (`JCSECT`, `JCALL`, `GOIF`,
`JHEAD`, `JSAVE`), so a plain search for `CSECT` returns nothing across all 39
files. Search for the macro names or the comment text instead. Separately, a
`grep` wrapper configured with `-I` silently returns no matches on files
containing control bytes — use `command grep -a` when a confident-looking
negative result matters.

**Empirical method.** Findings are produced by running `as370` on minimal sources
and decoding the 80-byte EBCDIC object deck: ESD section length at offset 29-31 of
the ESD card, TXT payload at offset 16 with its length at 10-11. The `-a=FILE`
listing gives the per-statement location counter directly and is the fastest way
to see a layout shift. Reference captures against a real IFOX00 go through
`tests/oracle/capture.py`.
