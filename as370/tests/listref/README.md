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
