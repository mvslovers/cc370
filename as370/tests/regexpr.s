* cc370 -- a register operand that begins with a GROUPING
* parenthesis.  IKJEBELT writes CVB (LINUM2+CTR)/TWO,... and
* means register 8; as370 read the '(' as a subscript and put
* register 0 into the instruction.
*
* Controls are inside the fixture: R8 names the same register
* without a parenthesis, and (EIGHT) is the fully enclosing
* form that already worked.  All four must name register 8.
REGX     CSECT
         USING REGX,15
A        EQU   14
B        EQU   2
TWO      EQU   2
EIGHT    EQU   8
AREA     DS    D
         CVB   (A+B)/TWO,AREA
         CVB   EIGHT,AREA
         CVB   (EIGHT),AREA
         L     (A+B)/TWO,AREA
         L     EIGHT,AREA
         LR    (A+B)/TWO,EIGHT
         END
