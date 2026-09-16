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
* Two EQUs carry the second control.  TCBLEN holds 16 and TCBTCB is
* the field at 12; R12 holds 12 and PARMPTR is the fullword at 8.
* An absolute EQU keeps the section its card was written in and holds
* no address in it, so a scan that takes them for addresses answers
* TCBLEN for 16 and R12 for 12 -- and R0 EQU 0 through R15 EQU 15 is
* what every real module writes.
*
* An unnamed DSECT is here for the name rendering and an EXTRN for a
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
R12      EQU   12                     a register EQU, as every
*                                     real module writes it
         EXTRN EXTSYM
         USING TCB,13
         USING *,15
BEGIN    MVC   8(4,13),12(1)          6 bytes
         BR    14                     2 bytes: PARMPTR lands at 8
PARMPTR  DC    A(0)
         END   BEGIN
