# IFOX00 listing reference (MVS 3.8j)

`ifox-listing-tstlist.txt` is the SYSPRINT listing produced by IFOX00 (PGM=IFOX00,
PARM='NODECK,LIST,NOLOAD,XREF(FULL),RENT') for the source in `tstlist.s`, captured
from mvsdev.lan via the mvsMF jobs API. It is the column-exact reference the as370
`-a` listing must match: ESD, source listing (with macro expansion `+` lines),
RELOCATION DICTIONARY, CROSS-REFERENCE, LITERAL CROSS-REFERENCE, DIAGNOSTICS,
STATISTICS, OPTIONS. Page header: `ASM 0201  HH.MM  MM/DD/YY`, LINECOUNT(55).
