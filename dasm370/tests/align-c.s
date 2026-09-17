* cc370#384 case 2: two insertions, of TWO and FOUR bytes, that move
* every displacement by EIGHT.  See the header of align-a.s.
*
ALIGNX   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
         LR    5,5
         A     2,VAL2
         LR    6,6
         LR    7,7
         ST    2,VAL
         L     3,VAL2
         BR    14
VAL      DC    F'1'
VAL2     DC    F'2'
         END
