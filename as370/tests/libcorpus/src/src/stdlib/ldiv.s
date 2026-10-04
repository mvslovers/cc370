         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ldiv prologue
LDIV     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ldiv code
         SLR   6,6
         SLR   7,7
         LR    2,6
         LR    3,7
         LR    4,6
         LR    5,7
         LR    15,0
         L     8,0(11)
         L     9,4(11)
         LR    2,8
         SRDA  2,32
         DR    2,9
         LR    6,3
         LR    4,8
         SRDA  4,32
         DR    4,9
         LR    7,4
         ST    6,0(15)
         ST    7,4+0(15)
* Function ldiv epilogue
         PDPEPIL
* Function ldiv literal pool
         DS    0F
         LTORG
* Function ldiv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
