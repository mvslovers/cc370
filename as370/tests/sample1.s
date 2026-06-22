TEST     CSECT
         BALR  12,0
         USING *,12
         L     15,=V(EXTSUB)
         LA    1,DATA
         BR    14
DATA     DC    A(TEST)
         LTORG
         END   TEST
