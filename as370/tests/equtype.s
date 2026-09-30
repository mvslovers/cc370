         MACRO
         TYP   &S
         LCLC  &T
&T       SETC  T'&S
         DC    C'&T'
         MEND
P1EQUT   CSECT
A        EQU   X'40',,C'X'
B        EQU   X'40',4,C'F'
C        DC    F'0'
         TYP   A
         TYP   B
         TYP   C
         DC    AL1(L'B)
         END
