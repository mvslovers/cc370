         MACRO
&L       INNER &R
&L       LR    &R,1
         MEND
         MACRO
&L       OUTER &R,&V=0
&L       INNER &R
         L     &R,=F'&V'
         MEND
T        CSECT
         USING T,12
A        OUTER 3,V=42
         OUTER 4
         BR    14
         LTORG
         END   T
