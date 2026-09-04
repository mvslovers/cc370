# ld370 against the linkage editor — divergences, options, and how they were found

**What this is.** The reference half of a differential reading of `ld370` against
the actual IEWL implementation — not against documentation, and not against
IEWL's *output*. It holds the material that has no other owner: the method, the
option comparison, the provenance caution, and the pointers to the issues the
reading produced.

**The findings themselves live in the tracker**, one issue each, with the
reproducer and the code citation:

| | finding | state |
|---|---|---|
| [#99](https://github.com/mvslovers/cc370/issues/99) | a WX parsed before an ER leaves a hard unresolved reference unreported | **fixed**, `62e4f1a` |
| [#100](https://github.com/mvslovers/cc370/issues/100) | every linked module is marked RENT+REUS; IEWL defaults to neither | read from both sources |
| [#101](https://github.com/mvslovers/cc370/issues/101) | the module image buffer is a fixed 1 MB static with no bounds check | latent, not active |
| [#102](https://github.com/mvslovers/cc370/issues/102) | a duplicate CSECT keeps the last definition; IEWL keeps the first | derived, needs a fixture |
| [#103](https://github.com/mvslovers/cc370/issues/103) | a second COMMON takes the last length; IEWL takes the maximum | derived, needs a fixture |

#99 is the only one that was ever reproduced, and it is now fixed — `g_intern`
promotes a `WX` matched by anything but another `WX` to `ER`, the way `HEWLFESD`
does. #102 and #103 name the input that would trigger them and nothing more —
that is what their fixtures are for.

It is worth recording what shape #99 turned out to be, because it is **not** the
buffer shape below. Nothing overflowed and nothing was truncated: two tests
decided one symbol's fate off two different tables, and the merge function that
fed them updated a type only when it *created* an entry. Order of the input
objects then decided whether a hard reference was diagnosed. The general lesson
is narrower than "check your bounds" — **a merge rule that only ever writes on
first sight is an order dependency**, and an order dependency in a linker is
invisible until someone reorders the link.

---

## The settled record — four defects of one shape

Kept because it is the pattern, not the history. All four are fixed.

| defect | symptom | fix |
|---|---|---|
| `o->text` fixed `[1<<14]`; TXT cards past 16 K silently dropped | S0C1 past ~16 KB, module already short on disk | `de39a60` |
| `rld[512]` / `ld[64]` fixed, no bounds check; RLD spill overwrote LD entries | exported LD symbols vanish → "unresolved" at a *later* link | `6e4dbef` |
| RLD *records* emitted oversized | fetch reads past its 256-byte `FTRBUF` → S106 rsn 0E | `47a6cc7` |
| `--pack` PDS directory built in one fixed `dir[256]` | SIGABRT at ≥7 members, no diagnostic | `c914122` |

Same shape every time: **a fixed-size buffer, no bounds check, silent wrong
output.** None produced a diagnostic; each surfaced as a runtime abend or a
phantom link failure, far from its cause. Two of them stayed latent purely
because the corpus had never contained the triggering input — one needed an
object with >512 RLD items, the other a 7th member. #101 is the same array
pattern still in the file.

Two lessons from PM-2026-002 (`knowledge/postmortems/`), worth restating:

> When "the image is complete" is an inference, scan the bytes before theorising
> about the reader. AMBLIST, the control records and the CCW counts are all the
> linker's own account of itself. They are perfectly consistent with a linker
> that declares N bytes and writes fewer.

> Our own tools produced structurally valid, silently wrong output. Suspect them
> before suspecting MVS.

Full write-ups: `knowledge/postmortems/PM-2026-002-ld370-text-truncation.md`,
`docs/multitext-fetch-truncation.md`,
`rexx370/docs/toolchain-ld370-ld-symbol-resolution.md`,
`rexx370/docs/toolchain-ld370-pack-directory-overflow.md`.

---

## Reviewed and sound — no action

Recorded so nobody re-derives them.

**ESD-ID numbering for LD entries is correct.** Checked specifically because it
is easy to get wrong. `parse_object` skips LD items *before* incrementing the ID
counter, so LD entries do not consume ESDIDs; `as370` assigns them the same way
(only `ESD_SECT` and `ESD_ER` take an id). Reader and writer agree, and both
agree with the object-deck format — an ESD card's cols 15-16 hold the ESDID of
the first *non-LD* item, and as370 leaves the field blank on an LD-only card.

**RLD emission is sound.** The R/P continuation bit is reset at every record
boundary, the input object's own continuation bit is masked out of the inherited
flag, and `RLDMAX = 236` holds. (The one defect this area did have — an inherited
continuation bit surviving onto a record's last item — was #41, fixed.)

**`SD` + `LR` on the same name is a note, not a finding.** The guard in the LD
loop only catches entries that are already resolved LRs, so an LD whose name
matches an existing CSECT stamps `type = 0x03` onto an `is_sect = 1` entry. IEWL
diagnoses this instead (`ESD15` → `DBLDEF`, message text *"IS DOUBLY DEFINED --
ESD TYPE"*). Whether `as370` can even emit an ENTRY with the same name as a
CSECT was **not checked** — verify that before spending time on it.

**Pseudo registers (PR, ESD type `0x06`) are not handled.** Only a PR collects a
PR, the length is the maximum and the alignment the OR of both values
(`ESD9`/`ESD10`); `FREELINE` additionally forces a fresh CESD line for PRs, with
IBM's own comment noting pseudo registers must be in order of appearance — so
the order is part of the contract. This is the linker half of
[#76](https://github.com/mvslovers/cc370/issues/76), and a C toolchain does not
generate pseudo registers.

---

## Options, against IEWL's PARM table

Reference: `OPTFIELD` in `HEWLFOPT` (`lked3.txt:12793-12831`) — 22 positive
options plus 8 `NO...` forms. The parallel action list at `:12833` holds one
instruction per option, EXecuted on match, so it is **not** a defaults table;
the defaults are set in `HEWLFINT`, which is how #100 was established.

**ld370 supports:** `-o`, `-e/--entry`, `-i/--include`, `-l`/`-L`,
`--allow-unresolved`, `--ac`, `--norent`, `--noreus`, `--blocksize`, `--dsn`,
`--name`, `--pack`, `--verbose`, `-xmit`, `-iebcopy`, `-v`.

Most absences are not defects — ld370 is a declared subset. Two are worth acting
on:

- **No module MAP or XREF.** IEWL has `MAP` (module structure) and `XREF`
  (cross-reference including the map). `--verbose` narrates the link to stderr
  but produces no IEWL-format map. When a link goes wrong, the map — which
  section landed where, who references whom — is the single most useful
  diagnostic there is, and it is what you reach for *after* the link succeeded
  but the module misbehaves. Filed as
  [#9](https://github.com/mvslovers/cc370/issues/9).
- **`ld370 --help` does not exist.** It is parsed as a filename:
  `--help: No such file or directory`. There is only a usage string on the error
  path. `as370` has a proper `--help`. Trivial, unfiled, and awkward for a tool
  being handed to anyone else.

**Present in IEWL, absent in ld370, no known consequence** — `OL`, `NE`, `TEST`,
`REFR`, `DC`, `DCBS`, `HIAR`, `SIZE`, `SCTR`, `ALIGN2`, `TERM`, `LET`, `LIST`,
`XCAL`, `NCAL`/`CALL` (ld370 autocalls only when `-l` is given, so `NCAL` is the
implicit default). Of these, **`REFR` is worth four lines** if the attribute
handling is touched for #100 anyway — another `PDS2ATR1` bit with no control.

`OVLY` is **not** an option gap: ld370 has no overlay support at all. Different
conversation.

### A caution about the reference itself — `PRINT` / `NOPRINT`

`HEWLFOPT`'s own header comment documents them as options 7 and 8
(`lked3.txt:12072`), there is a supporting mask constant `NOXML` at `:12246`
described as turning off XREF, MAP and LIST for NOPRINT, and a section comment
at `:12459` claiming to delete header messages under NOPRINT.

**None of it is implemented in this version.** `PRINT`/`NOPRINT` do not appear in
`OPTFIELD`; `NOXML` occurs exactly once in the entire 23 000-line source — its own
definition — and is never referenced; and the code under that section comment
contains no NOPRINT test at all.

The method note that follows from it: **in this source the prose and the code
disagree, and the option table is the authority.** Anyone mining IEWL for
behaviour should confirm against `OPTFIELD` and the action list rather than the
header comments. The same caution applies to IFOX00 — see
`as370/docs/ifox-option-parity.md`.

---

## Reference sources

**IBM OS/VS2 Release 3.7 Linkage Editor source**, as distributed on the SLAC
`LKED37` tape (SLAC modifications by B. J. Plescher and G. J. Mushial, 1977).
Local copy: `~/Downloads/lked_src/`, one `.txt` per tape file. Not in this
repository and not to be committed to it.

All `lked3.txt:NNNN` citations refer to **file 3 (`SOURCE`)** — the complete
linkage-editor source in IEBUPDTE format, 23 members. The relevant member
throughout is **`HEWLFESD`**, the ESD card processor / CESD collection logic
(`lked3.txt:4374-5254`).

Two practical notes for anyone opening these files:

- The doc files (`lked12`–`lked14`) contain `0xD7` overstrike bytes. A `grep`
  wrapper configured with `-I` (skip binary files) silently returns **no
  matches** on them. Use `command grep -a`.
- File 3 is a merged, already-modified source. File 4 is the SLAC patch deck
  against IBM's virgin source, in **IEBUPDTX** format (not IEBUPDTE — the control
  cards differ). Of the 25 CSECTs the build links, 24 are present in file 3; only
  `HEWLFDEF`, the defaults CSECT, is absent.

**Provenance — read before going further.** This is OS/VS2 R3.7. The
public-domain argument commonly made in the hobbyist community applies
specifically to MVS **3.8/3.8j** and should not be assumed to carry over; the
SLAC modifications additionally have their own authorship. The findings above
were produced by *reading the reference to establish record-format and collection
semantics* — facts about a file format, also documented in IBM's public Program
Logic Manuals — not by transliterating its code, and this document deliberately
cites routines and line numbers rather than reproducing the source. Keep that
line.

**IFOX00 assembler source** — `~/repos/mvs/ifox-src/`, ~15 MB of HLASM.
Authoritative for what the *producer* of an object deck emits, and cited in #103.
Useful entry points: `ifnx5a.asm` (assembly phase: DC/DS/DXD processors,
`RLDOUT`), `ifnx5p.asm` (`PUNRTN`, the object-deck punch). The sources are
macro-driven (`JCSECT`, `JCALL`, `GOIF`, `JHEAD`), so a plain grep for `CSECT`
finds nothing — search for the macro names or the comment text instead.

**Our own format documentation** — independent of the above, and the better first
stop: `docs/object-module-format.md`, `docs/load-module-format.md`,
`docs/entry-point-resolution.md`, `docs/unload-format.md`, `docs/xmit-format.md`.

Code cited throughout: `ld370/src/ld370.c`, `as370/src/as370.c`.
