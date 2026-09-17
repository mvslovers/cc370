* cc370#384 case 1: `align-a.s' with ONE four-byte insertion.
* See the header of align-a.s for what it is here to prove.
*
ALIGNX   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
         A     2,VAL2
         A     2,VAL2
         ST    2,VAL
         L     3,VAL2
         BR    14
VAL      DC    F'1'
VAL2     DC    F'2'
         END
