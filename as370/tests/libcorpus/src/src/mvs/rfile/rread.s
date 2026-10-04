         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rread prologue
RREAD    PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rread code
         L     2,0(11)
         L     8,8(11)
         SLR   3,3
         ST    3,108(13)
         MVC   104(4,13),28(2)
         MVC   88(4,13),24(2)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AREAD)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         LA    3,1(0,0)
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         L     2,108(13)
         L     6,4(11)
         LR    7,2
         L     4,104(13)
         LR    5,2
         MVCL  6,4
         LTR   8,8
         BE    @@L3
         MVC   0(4,8),108(13)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function rread epilogue
         PDPEPIL
* Function rread literal pool
         DS    0F
         LTORG
* Function rread page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
