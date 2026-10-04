         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __stymd prologue
@@STYMD  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __stymd code
         SLR   2,2
         SLR   3,3
         LR    4,2
         LR    5,3
         LR    6,2
         LR    7,3
         L     9,0(11)
         LR    8,9
         MH    8,=H'400'
         LR    2,8
         SRDA  2,32
         L     15,=F'146097'
         DR    2,15
         B     @@L2
@@L4     EQU   *
         A     3,=F'1'
@@L2     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@YTD)
         BALR  14,15
         CR    15,9
         BL    @@L4
         LR    4,8
         SRDA  4,32
         L     2,=F'146097'
         DR    4,2
         LR    3,5
         B     @@L5
@@L7     EQU   *
         A     3,=F'1'
@@L5     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@YTD)
         BALR  14,15
         CR    15,9
         BL    @@L7
         L     4,4(11)
         ST    3,0(4)
         BCTR  3,0
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@YTD)
         BALR  14,15
         LR    3,9
         SR    3,15
         LA    15,59(0,0)
         CLR   3,15
         BNH   @@L8
         A     3,=F'2'
         MVC   88(4,13),0(4)
         LA    1,88(,13)
         L     15,=V(@@ISLEAP)
         BALR  14,15
         LTR   15,15
         BE    @@L8
         LR    2,3
         BCTR  2,0
         LA    4,62(0,0)
         CLR   3,4
         BH    @@L11
         BCTR  2,0
@@L11    EQU   *
         L     12,0(,10)
         LR    3,2
@@L8     EQU   *
         L     12,0(,10)
         LR    2,3
         MH    2,=H'100'
         LR    6,2
         A     6,=F'3007'
         SRDL  6,32
         LA    15,3057(0,0)
         DR    6,15
         L     2,8(11)
         ST    7,0(2)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@MTD)
         BALR  14,15
         SR    3,15
         L     2,12(11)
         ST    3,0(2)
* Function __stymd epilogue
         PDPEPIL
* Function __stymd literal pool
         DS    0F
         LTORG
* Function __stymd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
