*---------------------------------------------------------------
* as370 issue #68 -- the END literal pool belongs to the FIRST
* control section.
*
* IFOX00 (xfour.asm, ENDING) resumes the first control section at
* its highest address when END is reached with a non-empty pool,
* assembles the pool there and puts the location counter back --
* so the pool's bytes are PUNCHED last, after every other TXT
* card, but carry the first section's ESDID and an address inside
* it, and every section behind the first moves up by what the
* pool took.  "First control section" is IFOX's FSTCSECT: the
* first section that is neither DSECT nor COM.
*
* The rule is validated against IFOX00's own object deck on the
* reporter's three-section ksdsnatr (issue #68).  This module is
* the mechanism test, and it covers three things ksdsnatr does
* not:
*
*   - an LTORG *after* the first control section is closed, so
*     the pool END flushes is not the pool that was open at the
*     boundary, and the LTORG's own pool must stay where it is
*   - a literal first referenced from a LATER section, which then
*     has to resolve through a USING covering the FIRST one
*   - an =A literal in the moved pool, whose RLD names the first
*     section as both P and R
*
* Expected layout -- derived from the rule above, not read off an
* oracle deck (there is none for this module):
*
*   POOLA  0x000000  len 0x20   content ends 0x12, pool at 0x18
*   POOLB  0x000020  len 0x0D
*   POOLC  0x000030  len 0x0E   keeps the LTORG's own pool, 0x30
*   END pool  =F'2' at 0x18, =A(ATAB) at 0x1C, in POOLA
*---------------------------------------------------------------
POOLA    CSECT
         BALR  12,0
         USING *,12
         L     1,=F'1'        pool 0
         MVC   ATAB(2),=C'AB' pool 0
ATAB     DS    CL2
         DS    XL4
POOLB    CSECT               first section closes here
         DS    XL13
POOLC    CSECT
         USING POOLA,11
         LTORG               pool 0 lands here, in POOLC
         L     2,=F'2'       pool 1 -- the END pool
         L     3,=A(ATAB)    pool 1, and an adcon
         END
