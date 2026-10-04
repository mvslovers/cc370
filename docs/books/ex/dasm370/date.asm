DATE     CSECT
         BALR  12,0
         USING *,12
         LTR   1,1
         BZ    OUT
         LA    1,1
OUT      BR    14
DAT      DC    C'26.123'
         END
