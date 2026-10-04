         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsxerr prologue
@@VSXERR PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsxerr code
         L     4,0(11)
         LR    5,4
         A     5,=F'-104'
         LA    6,96(,13)
         LA    7,64(0,0)
         SLR   2,2
         LR    3,2
         MVCL  6,2
         MVC   160(4,13),=F'0'
         IC    6,17(5)
         O     6,=F'2'
         STC   6,17(5)
         LA    3,96(,13)
         LA    2,160(,13)
         
         SHOWCB RPL=(4),                                               X
               FIELDS=FDBK,AREA=(2),LENGTH=4,MF=(G,(3))
         MVC   18(1,5),161(13)
         MVC   20(1,5),162(13)
         MVC   19(1,5),163(13)
         L     4,184(5)
         LTR   4,4
         BE    @@L2
         LR    3,6
         N     3,=XL4'000000FF'
         LR    2,3
         N     2,=F'64'
         LTR   2,2
         BNE   @@L4
         N     3,=F'32'
         LTR   3,3
         BE    @@L2
@@L4     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         LA    1,88(,13)
         LA    15,0(4)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         L     15,4(11)
* Function __vsxerr epilogue
         PDPEPIL
* Function __vsxerr literal pool
         DS    0F
         LTORG
* Function __vsxerr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
