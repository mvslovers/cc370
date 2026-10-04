COUNT    CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         LA    15,0
         L     2,TABLEA
         LA    3,4
LOOP     A     15,0(,2)
         LA    2,4(,2)
         BCT   3,LOOP
         LM    0,12,20(13)
         L     14,12(,13)
         BR    14
TABLEA   DC    A(TABLE)
TABLE    DC    F'1,2,3,4'
         END   COUNT
