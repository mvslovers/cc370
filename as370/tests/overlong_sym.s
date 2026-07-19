* issue #20: an over-length EXTERNAL symbol must be diagnosed, not silently
* truncated.  PREFIXAB1 and PREFIXAB2 are two distinct external names that
* share their first 8 characters; MVS object-deck (ESD) names are limited to 8
* bytes, so both truncate to PREFIXAB.  as370 used to store the truncated name
* on insert while comparing the full name on lookup, so the two landed on one
* ESD entry with no diagnostic (rc=0) -- a silent mislinkage: at link one binds
* over the other.  IFOX00 (Assembler XF) rejects an over-length symbol (ERR187
* "SYMBOL LONGER THAN 8 CHARACTERS", severity 8); as370 must too -- flag each
* over-length EXTERNAL symbol (RC 8), catching the collision at assemble time.
* This mirrors the cc370 `-S` output of the issue's C reproducer (extern int p
* __asm__("PREFIXAB1"); ... -> ENTRY PREFIXAB1 / ENTRY PREFIXAB2).  (An
* over-length ordinary name-field label or EQU name is a separate truncation
* site -- parse() caps it to 8 -- and is not yet flagged: see #32.)
OVLTEST  CSECT
         ENTRY PREFIXAB1
         ENTRY PREFIXAB2
PREFIXAB1 DC   F'1'
PREFIXAB2 DC   F'2'
         END
