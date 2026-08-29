# IFOX00 listing reference (MVS 3.8j)

`ifox-listing-tstlist.txt` is the SYSPRINT listing produced by IFOX00 (PGM=IFOX00,
PARM='NODECK,LIST,NOLOAD,XREF(FULL),RENT') for the source in `tstlist.s`, captured
from mvsdev.lan via the mvsMF jobs API. It is the column-exact reference the as370
`-a` listing must match: ESD, source listing (with macro expansion `+` lines),
RELOCATION DICTIONARY, CROSS-REFERENCE, LITERAL CROSS-REFERENCE, DIAGNOSTICS,
STATISTICS, OPTIONS. Page header: `ASM 0201  HH.MM  MM/DD/YY`, LINECOUNT(55).

## A fixture with a listing here is an oracle input

IFOX00 printed the fixture's **comment cards** into the SOURCE STATEMENT column
and numbered every statement from them. The fixture and its listing are therefore
one artifact: change a comment card alone and the listing's source column, and
every statement number that follows it, are quietly wrong.

Two rules follow, and both were learned the hard way on `undefsym.s`:

1. **Never edit a fixture in place.** Rewrite it and re-capture the listing in the
   same change (`tests/oracle/capture.py`, one job, `--listing` leaves nothing on
   the guest). A fixture edited without a re-capture plants the failure for
   whoever later wires that listing into `check.sh` — which this file asks for in
   three places.
2. **Write the header so it cannot go stale.** Describe the *source*, and the
   oracle's behaviour, which never changes. Say what as370 did in the **past
   tense** — `multi_csect.s` ("as370 looked up the module's first section") and
   `fltoracl.s` (what the deck pins) both survive their own fix. `undefsym.s` was
   written in the present tense about as370's then-current behaviour, and read as
   a lie the day #82 landed.

And keep every card inside **column 71**. A sixth comment card was tried on
`undefsym.s` while closing #82, reached column 72, and under the continuation
rule of #72 consumed `UNDEFSYM CSECT` outright — in the fixture for the
diagnostic about symbols lost to exactly that rule. `capture.py` warns per line,
but only once the job has run.

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

## `ifox-listing-undefsym.txt` — the undefined symbol (#82, closed)

IFOX00's SYSPRINT for `tests/undefsym.s` (JOB02870). Five `IFO188 … IS AN
UNDEFINED SYMBOL` over four flagged statements, `HIGHEST SEVERITY 8`, and — the
half that is easy to miss — **every flagged instruction assembled as all
zeros**, an invalid opcode:

```
000000 0000 0000            8          BE    NOWHERE
000004 0000 0000            9          LH    3,NOSUCH(,7)
000008 0000 0000 0000      10          MVC   FIELD-BASE(8,2),0(3)
```

as370 reproduces both halves since #82: the same three instructions come out
zero, the literal reference `L 4,=A(NOVAL)` stays `5840 F018` as IFOX assembles
it, and the five messages name NOWHERE / NOSUCH / FIELD / BASE / NOVAL at RC 8.
`tests/run.sh` asserts the object bytes, the message set and the RLD against this
listing, and carries a second case for the operand shapes that must NOT be read
as symbols (`X'40'`, `C'A'`, `B'1111'`, `L'FIELD`, `=A(…)`).

This listing was re-captured (JOB02899) when #82 closed, so the fixture's comment
cards and the reference agree again; against the JOB02870 capture nothing moved
but those five cards and IFOX's own timestamp.

`check.sh` does not compare this listing column by column — as370's listing page
has no `*** ERROR ***` markers and no diagnostics page. Two differences from the
reference are by design, and are recorded in the run.sh case:

| | IFOX00 | as370 |
|---|---|---|
| `NOVAL` is flagged at | stmt 14, the generated pool statement | stmt 11, the statement that wrote the literal |
| `NUMBER OF STATEMENTS FLAGGED` | 4 (stmt 10 raises two messages) | 5 — as370's counter counts messages |

The first follows `defln`, the way IFO158 already attributes a literal
diagnostic; as370's listing renders the pool line but has no `lines[]` entry to
hang a diagnostic on. The second is every recorder in `as370.c`, not this one.

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
