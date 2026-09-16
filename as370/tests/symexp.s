* The symbol export, and the one thing it exists to answer (#373).
*
* A displacement is written `8(4,13)' and has to come back as
* `TCBFSA(4)'.  That resolution is a filtered scan of the exported
* records -- the nearest value <= 8 among the symbols of the section
* register 13 addresses -- so the fixture writes the answer down
* independently of the export: TCBFSA is the THIRD fullword of TCB,
* which puts it at offset 8 with a length of 4, and nothing but the
* DS statements above it decides that.
*
* The control is the second 8.  PARMPTR sits at offset 8 of the
* CSECT, so a scan that ignores the section answers TCBFSA for one
* and PARMPTR for the other -- or the same name for both, which is
* the failure worth catching.
*
* An unnamed DSECT is here for the name rendering, an EQU for a
* value that is absolute rather than an address, and an EXTRN for a
* record whose value means nothing because it is never defined.
*
TCB      DSECT
TCBRBP   DS    A                      offset 0
TCBPIE   DS    A                      offset 4
TCBFSA   DS    A                      offset 8 -- the answer
TCBTCB   DS    A                      offset 12
TCBLEN   EQU   *-TCB                  16, and absolute
         DSECT                        no name: invent none
UNPARM   DS    F
SYMEXP   CSECT
         EXTRN EXTSYM
         USING TCB,13
         USING *,15
BEGIN    MVC   8(4,13),12(1)          6 bytes
         BR    14                     2 bytes: PARMPTR lands at 8
PARMPTR  DC    A(0)
         END   BEGIN
