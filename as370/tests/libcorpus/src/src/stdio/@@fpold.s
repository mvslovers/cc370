         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fpold prologue
@@FPOLD  PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpold code
         L     6,0(11)
         SLR   15,15
         ST    15,120(13)
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    4,120(,13)
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    4,88(13)
         A     6,=F'61'
         ST    6,92(13)
         A     6,=F'-61'
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXOLD)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         LH    2,40(6)
         N     2,=F'64'
         LTR   2,2
         BE    @@L6
         IC    2,52(6)
         CLM   2,1,=XL1'00'
         BNE   @@L6
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRLSE)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
@@L6     EQU   *
         L     12,0(,10)
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         LR    2,15
         BCTR  2,0
         L     4,120(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),1
         MVI   98(13),64
         MVC   104(4,13),120(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         L     2,120(13)
         L     2,0(2)
         MVC   43(8,6),6(2)
         OC    40(2,6),=H'-32768'
@@L3     EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L10
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L10    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __fpold epilogue
         PDPEPIL
* Function __fpold literal pool
         DS    0F
         LTORG
* Function __fpold page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
