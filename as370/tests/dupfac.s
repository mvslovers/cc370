* Parenthesised duplication factor on DC/DS (issue #93). Assembler XF
* takes an absolute expression in parentheses wherever a decimal
* self-defining term may stand (xdcds.asm:110).
DUPFAC   CSECT
AREASTA  DS    0H
         DS    CL40
AREAEND  DS    0H
CALCDC   DC    ((AREAEND-AREASTA)/8)X'00'
SIMPLEDC DC    (4)X'00'
CALCDS   DS    ((AREAEND-AREASTA)/8)X
ZERODC   DC    (0)X'00'
PLAINDC  DC    4X'00'
FWDDC    DC    ((FWDEND-AREASTA)/8)X'00'
FWDEND   DS    0H
NEGDC    DC    ((AREASTA-AREAEND)/8)X'00'
         END
