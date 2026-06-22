         CSECT
         ENTRY MAIN
MAIN     BALR  12,0
         USING *,12
         LR    11,1
         L     15,=V(SUB1)
         BALR  14,15
         LA    1,TAB
         BR    14
TAB      DC    A(MAIN)
         DC    A(MAIN)
FILL     DC    12F'0'
         LTORG
         END   MAIN
