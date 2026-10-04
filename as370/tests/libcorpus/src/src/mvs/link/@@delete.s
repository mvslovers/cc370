         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__delete'
* Program text area
         DS    0F
* X-func __delete prologue
@@DELETE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __delete code
         L     15,0(11)
         SLR   6,6
         LA    4,88(,13)
         LA    5,12(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LTR   15,15
         BE    @@L4
         CLI   0(15),64
         BNH   @@L4
         LA    4,88(,13)
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
         LA    2,88(,13)
         DELETE EPLOC=(2)
         LR    6,15         save return code
@@L4     EQU   *
         L     12,0(,10)
         LR    15,6
* Function __delete epilogue
         PDPEPIL
* Function __delete literal pool
         DS    0F
         LTORG
* Function __delete page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
