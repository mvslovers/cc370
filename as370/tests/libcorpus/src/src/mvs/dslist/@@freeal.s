         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __freeal prologue
@@FREEAL PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __freeal code
         L     7,0(11)
         LTR   7,7
         BE    @@L1
         L     2,0(7)
         LTR   2,2
         BE    @@L1
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L3
         L     2,0(7)
         SLR   6,6
         CLR   6,15
         BNL   @@L3
         LR    4,2
@@L9     EQU   *
         L     3,0(4)
         LTR   3,3
         BE    @@L6
         L     2,12(3)
         LTR   2,2
         BE    @@L8
         A     3,=F'12'
         ST    3,88(13)
         A     3,=F'-12'
         LA    1,88(,13)
         L     15,=V(@@FREEDS)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     4,=F'4'
         CLR   6,5
         BL    @@L9
@@L3     EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         MVC   0(4,7),=F'0'
@@L1     EQU   *
         L     12,0(,10)
* Function __freeal epilogue
         PDPEPIL
* Function __freeal literal pool
         DS    0F
         LTORG
* Function __freeal page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
