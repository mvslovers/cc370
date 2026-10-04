DEMO     TITLE 'OBJECT MODULE FORMAT'
         ENTRY ALT
         EXTRN SUB
         WXTRN OPT
MAIN     CSECT
         USING *,15
         L     15,=V(SUB)
         BR    14
ALT      DC    A(ALT)
         DC    AL3(MAIN)
         DC    V(OPT)
SECOND   CSECT
         DC    A(MAIN)
         DC    AL2(ALT)
         END   MAIN
