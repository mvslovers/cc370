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
as/tests/listref/check.sh        # CRENT=../../crent370 by default
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
