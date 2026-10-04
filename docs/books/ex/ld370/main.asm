MAIN     CSECT
         USING MAIN,15
         STM   14,12,12(13)
         L     15,=V(ADD1)
         LA    1,6
         BALR  14,15
         LM    0,12,20(13)
         L     14,12(,13)
         BR    14
         LTORG
         END   MAIN
