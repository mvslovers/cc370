         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsread prologue
@@VSREAD PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsread code
         L     6,0(11)
         L     8,4(11)
         L     15,12(11)
         L     7,16(11)
         LA    4,112(,13)
         LA    5,64(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         MVC   176(4,13),=F'0'
         LTR   15,15
         BE    @@L2
         LTR   7,7
         BE    @@L2
         ST    6,88(13)
         ST    8,92(13)
         MVC   96(4,13),8(11)
         ST    15,100(13)
         ST    7,104(13)
         LA    1,88(,13)
         L     15,=V(@@VSSTEQ)
         BALR  14,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    8,92(13)
         MVC   96(4,13),8(11)
         ST    15,100(13)
         ST    7,104(13)
         LA    1,88(,13)
         L     15,=V(@@VSMDFY)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         IC    3,17(6)
         N     3,=F'-33'
         STC   3,17(6)
         LR    4,6
         A     4,=F'104'
         LA    2,GETDONE
         GET   RPL=(4)
GETDONE  DS    0H
         ST    15,176(13)
         N     3,=XL4'000000FF'
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BE    @@L4
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'154'
         MVC   8(4,11),=F'-2'
         B     @@L5
@@L4     EQU   *
         L     12,0(,10)
         N     3,=F'1'
         LTR   3,3
         BE    @@L6
         MVC   8(4,11),=F'-1'
         B     @@L5
@@L6     EQU   *
         L     12,0(,10)
         LA    3,112(,13)
         LA    2,8(,11)
         SHOWCB RPL=(4),FIELDS=RECLEN,AREA=(2),LENGTH=4,MF=(G,(3))
@@L5     EQU   *
         L     12,0(,10)
         L     15,8(11)
* Function __vsread epilogue
         PDPEPIL
* Function __vsread literal pool
         DS    0F
         LTORG
* Function __vsread page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
