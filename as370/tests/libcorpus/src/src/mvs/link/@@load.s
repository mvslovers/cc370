         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__load'
* Program text area
         DS    0F
* X-func *@@LOAD prologue
@@LOAD   PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@LOAD code
         L     6,0(11)
         L     15,4(11)
         L     8,8(11)
         L     9,12(11)
         SLR   7,7
         LA    4,96(,13)
         LA    5,80(0,0)
         LR    2,7
         LR    3,7
         MVCL  4,2
         LTR   15,15
         BE    @@L4
         CLI   0(15),64
         BNH   @@L4
         LA    4,100(,13)
         LA    5,7(0,0)
@@L10    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L8
         N     2,=XL4'000000FF'
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
         A     15,=F'1'
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         MVI   0(4),64
@@L7     EQU   *
         L     12,0(,10)
         BCTR  5,0
         A     4,=F'1'
         LTR   5,5
         BNL   @@L10
         LA    2,96(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@BLDL)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         LA    2,100(,13)
         LOAD DE=(2),DCB=(6),ERRET=LOADFAIL
         LR    7,0          Success, save EPA
         LR    3,1          Success, save AC and Size
         B     LOADDONE
LOADFAIL DS    0H
         XR    7,7         Failed, no EPA
         XR    3,3         Failed, no AC or Size
LOADDONE DS    0H
         LTR   7,7
         BE    @@L4
         LTR   8,8
         BE    @@L13
         LR    2,3
         SLL   2,3
         N     2,=F'134217720'
         ST    2,0(8)
@@L13    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L4
         SRL   3,24
         STC   3,0(9)
@@L4     EQU   *
         L     12,0(,10)
         LR    15,7
* Function *@@LOAD epilogue
         PDPEPIL
* Function *@@LOAD literal pool
         DS    0F
         LTORG
* Function *@@LOAD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
