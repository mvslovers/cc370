* issue #32: an over-length ORDINARY symbol (a local label / EQU name) must be
* diagnosed the way real IFOX00 does -- NOT truncated silently.  Pinned against
* IFOX00 on MVS 3.8j (JOB00256, RC=8): IFOX rejects the over-length NAME FIELD
* (IFO016 "ILLEGAL OR INVALID NAME FIELD", sev 8) and does NOT enter the symbol,
* and rejects an over-length symbol TERM in an operand expression (IFO236
* "ILLEGAL CHARACTER IN EXPRESSION", sev 8), zeroing the whole instruction.  It
* does NOT truncate-and-continue (that is the ENTRY/EXTRN ERR187 path, #20) and
* does NOT truncate a reference to make it resolve.  8-char names stay clean.
TESTOVL  CSECT
         USING TESTOVL,15
EIGHTCHR DS    F
LONGLABEL9 DS  F
NINECHAR9 DS   F
         L     1,LONGLABEL9
         L     2,EIGHTCHR
         L     3,NINECHAR9
BIGEQUNAME EQU 5
         LA    4,BIGEQUNAME
         L     5,EIGHTCHRX
         END
