* Control: same entry point, no second operand.  This card
* is already correct today and must not move.
SECTA    CSECT
         BR    14
SECTB    CSECT
ENTB     BR    14
         END   ENTB
