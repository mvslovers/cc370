         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __patmat prologue
@@PATMAT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __patmat code
         L     3,0(11)
         L     4,4(11)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L2
@@L31    EQU   *
         CLI   0(3),64
         BNE   @@L26
         A     3,=F'1'
         B     @@L31
@@L26    EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L8
         B     @@L7
@@L2     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'5C'
         BNE   @@L9
@@L32    EQU   *
         CLI   1(4),92
         BNE   @@L28
         A     4,=F'1'
         B     @@L32
@@L28    EQU   *
         L     12,0(,10)
         IC    2,1(4)
         CLM   2,1,=XL1'00'
         BE    @@L7
@@L34    EQU   *
         A     3,=F'1'
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L8
         IC    2,1(4)
         CLM   2,1,0(3)
         BE    @@L17
         CLM   2,1,=XL1'6F'
         BNE   @@L34
@@L17    EQU   *
         L     12,0(,10)
         A     3,=F'1'
         ST    3,88(13)
         BCTR  3,0
         A     4,=F'2'
         ST    4,92(13)
         A     4,=F'-2'
         LA    1,88(,13)
         L     15,=A(@@PATMAT)
         BALR  14,15
         LTR   15,15
         BNE   @@L7
         B     @@L34
@@L9     EQU   *
         L     12,0(,10)
         IC    15,0(3)
         CLM   15,1,=XL1'00'
         BE    @@L8
         CLM   2,1,=XL1'6F'
         BE    @@L23
         STC   2,80(,13)
         CLM   15,1,80(13)
         BNE   @@L8
@@L23    EQU   *
         L     12,0(,10)
         A     3,=F'1'
         ST    3,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@PATMAT)
         BALR  14,15
         LTR   15,15
         BNE   @@L7
@@L8     EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L1
@@L7     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function __patmat epilogue
         PDPEPIL
* Function __patmat literal pool
         DS    0F
         LTORG
* Function __patmat page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
