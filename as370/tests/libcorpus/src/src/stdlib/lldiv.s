         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func lldiv prologue
LLDIV    PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function lldiv code
         LR    7,0
         L     2,0(11)
         L     3,4+0(11)
         L     4,8(11)
         L     5,4+8(11)
         LA    6,120(,13)
         ST    2,88(13)
         ST    3,4+88(13)
         ST    4,96(13)
         ST    5,4+96(13)
         LR    0,6
         LA    1,88(,13)
         L     15,=V(@@DIVDI3)
         BALR  14,15
         MVC   104(8,13),120(13)
         ST    2,88(13)
         ST    3,4+88(13)
         ST    4,96(13)
         ST    5,4+96(13)
         LR    0,6
         LA    1,88(,13)
         L     15,=V(@@MODDI3)
         BALR  14,15
         MVC   112(8,13),120(13)
         MVC   0(16,7),104(13)
         LR    15,7
* Function lldiv epilogue
         PDPEPIL
* Function lldiv literal pool
         DS    0F
         LTORG
* Function lldiv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
