# IFOX00 listing reference (MVS 3.8j)

`ifox-listing-tstlist.txt` is the SYSPRINT listing produced by IFOX00 (PGM=IFOX00,
PARM='NODECK,LIST,NOLOAD,XREF(FULL),RENT') for the source in `tstlist.s`, captured
from mvsdev.lan via the mvsMF jobs API. It is the column-exact reference the as370
`-a` listing must match: ESD, source listing (with macro expansion `+` lines),
RELOCATION DICTIONARY, CROSS-REFERENCE, LITERAL CROSS-REFERENCE, DIAGNOSTICS,
STATISTICS, OPTIONS. Page header: `ASM 0201  HH.MM  MM/DD/YY`, LINECOUNT(55).

## What as370 produces, and how it is checked

`check.sh` assembles `tstlist.s` with `-a` and compares the **ESD**, **SOURCE
STATEMENT** (with object code, ADDR1/ADDR2, statement numbers, the macro
expansion `+` lines, and the library sequence numbers in cols 73-80 carried
through) and **RELOCATION DICTIONARY** sections against this reference,
byte-for-byte:

```sh
as/tests/listref/check.sh        # LIBC370=../../libc370 by default
```

Two differences from the IFOX reference are expected and tolerated:

1. **Header identity block** (the right-justified `ASM 0201 HH.MM MM/DD/YY` on the
   column-header lines): as370 stamps its *own* translator id there, not IFOX's.
   The check masks cols 90+ on those header lines.
2. **`*** ERROR ***`** after the MVC at stmt 15: IFOX's inline IFO229
   reentrancy diagnostic. as370 has no reentrancy checker, so it does not emit
   this line; the check drops it.

Not yet produced (excluded from the comparison): the CROSS-REFERENCE, LITERAL
CROSS-REFERENCE, DIAGNOSTICS and STATISTICS/OPTIONS pages.

## `ifox-listing-multi-csect.txt` — the multi-section case (#70)

The first reference here for a module with more than one control section, and
the reason it was needed: the ESD section's LENGTH column took its figure from
`modlen` for the first section and printed a hard zero for every other. With one
section `modlen` *is* that section's length, so all three references above agreed
with the wrong expression.

`check.sh` compares it down to `THIRD CSECT` and stops. Everything below is a
listing-rendering defect with its own issue — the object deck for this module is
byte-identical to IFOX00 throughout:

| line | as370 | IFOX00 | |
|---|---|---|---|
| `THIRD CSECT` | LOC `000014` | `000018` | pre-alignment LOC, #28 |
| `MYDS DSECT` | LOC `00001C` | `000000` | DSECT body, #24 |
| `DSFLD DS F` | object `00000010` | none | DSECT body, #24 |
| `END ENT2` | LOC blank | `000012` | entry-point address |

IFOX flags one statement in it, `IFO158` for the deliberate DSECT-adcon control
(#72), so the reference carries an `*** ERROR ***` marker like the other error
cases.

## `ifox-listing-cont72.txt` — the continuation-rule measurement (#72)

IFOX00's SYSPRINT for `tests/cont72.s` (JOB02846). It is the evidence that a
comment card reaching column 72 **consumes the next card**, statement or not:
`SWALLOW DC F'1'` is printed with no statement number, is absent from the
cross-reference, and `CONT72` comes out **eight** bytes rather than sixteen.
Three statements flagged, five `IFO026` and one `IFO069`, `HIGHEST SEVERITY 4`
-- code lost at warning level.

`check.sh` does not compare it column by column: as370's listing does not render
a statement's continuation cards, nor the diagnostics page. `tests/run.sh`
asserts what the deck and the diagnostics say instead (RC 4, the message counts,
the flagged-statement count, and the eight-byte section). Wire the columns in
when the listing renders continuation cards.

## `ifox-listing-fltoracl.txt` — captured, not yet wired in

The SYSPRINT from the same guest run that produced `tests/ref/fltoracl.obj`
(issue #53 step 3, floating point). It is committed because it is the expensive
half of that capture — a job on a real MVS 3.8j — and because it is the only
IFOX00 listing we hold for a module full of `DC` constants.

`check.sh` does **not** compare it yet, and it would fail today for one reason,
36 times: **IFOX prints a DC's alignment padding as its own object line and then
the constant at its aligned LOC; as370 prints the constant at the location
counter as it stood BEFORE the alignment**, with the pad bytes folded into its
object column.

```
IFOX00:  00001E 0000
         000020 4110000000000000     47 DPLAIN   DC    D'1'
as370:   00001E 0000411000000000     47 DPLAIN   DC    D'1'
```

The object decks are byte-identical — this is the rendering, not the assembly,
and it is the same pre-alignment-LOC defect as issue #28 (which records it for
`LTORG`). Wire this case in when that is fixed; the reference is already here.
