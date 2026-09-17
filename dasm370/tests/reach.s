* cc370#383: what the reachability traversal must reach, and what
* it must not.
*
* The shape is a PL/S module's: a branch over an eyecatcher through
* R15, which holds the entry point by MVS linkage convention; a
* prologue BALR establishing a base; that base copied with LR; and
* a jump table reached by loading a register from relocated words
* and branching through it.
*
* WHAT IT MUST NOT REACH is DEAD, which nothing branches to and
* which follows an unconditional branch -- and the EYECATCHER,
* which is the whole reason #383 exists: text decodes perfectly
* well as instructions.
*
* Keep every line under column 72.
*
REACHX   CSECT
         B     START-REACHX(0,15)       over the eyecatcher
EYE      DC    C'REACHX 78.215'         text that decodes as code
         DS    0H
START    BALR  12,0                     the prologue base
         USING *,12
         LR    11,12                    a base copied
         L     8,DTAB                   loaded and NEVER branched
         L     9,SEL
         SLA   9,2
         L     9,TABZ(9)                loaded from a relocated table
         BR    9                        branched through: PROMOTION
DEAD     LA    1,4(0,11)                nothing branches here
         LA    2,8(0,11)
         BR    14
T1       LA    3,1(0,12)
         BR    14
T2       LA    4,2(0,12)
         BR    14
         DS    0F
* TABZ is index 0: a null slot, so NO relocation covers it, which is
* why the promotion takes the run from the load's target OR from the
* word immediately after it.  Anchored strictly on the target it
* promotes nothing -- measured on BLSCAMER, whose own table begins
* the same way.
* DTAB is the case the first bullet forbids: an address constant
* pointing at the eyecatcher.  It is LOADED, and no register loaded
* from it is ever branched through, so it must stay a LABEL root and
* the eyecatcher must stay dark.  A promotion without the BR gate
* reaches EYE and this fixture fails.
DTAB     DC    A(EYE)
TABZ     DC    A(0)
TAB      DC    A(T1)
         DC    A(T2)
SEL      DC    F'0'
         END
