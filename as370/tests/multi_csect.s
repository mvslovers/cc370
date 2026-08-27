* issue #52 -- a symbol's OWNING control section, in the ESD and in the RLD.
*
* Both halves of the same root cause: as370 looked up the module's first
* section instead of the section the symbol is defined in.
*   ESD: the LD entry for an ENTRY in a second or later CSECT named ESDID 1.
*   RLD: an ordinary label carries no ESDID of its own, so a relocation whose
*        target lived in a sibling CSECT fell back to the CURRENT section.
*   END: the entry-point card names the section the entry point is IN, and the
*        loader adds that section's origin -- so a wrong ESDID there moves the
*        entry point, unlike the ESD's cosmetic one.
* PSELF and PCSNAME are the controls -- a same-section target, and a target
* that is itself a CSECT name (which has its own ESDID and was always right).
FIRST    CSECT
PCSNAME  DC    A(SECOND)
PLABEL   DC    A(LBL2)
PSELF    DC    A(LOCAL)
PDSECT   DC    A(DSFLD)
LOCAL    DS    0H
SECOND   CSECT
         ENTRY ENT2
         BR    14
LBL2     DS    0H
ENT2     DS    0H
         BR    14
THIRD    CSECT
PENT     DC    A(ENT2)
MYDS     DSECT
DSFLD    DS    F
         END   ENT2
