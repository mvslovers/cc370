         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsmdfy prologue
@@VSMDFY PDPPRLG CINDEX=0,FRAME=152,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsmdfy code
         L     9,0(11)
         L     3,4(11)
         L     2,8(11)
         L     8,12(11)
         LA    6,88(,13)
         LA    7,64(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         LR    4,9
         A     4,=F'104'
         LA    5,88(,13)
         
         MODCB RPL=(4),RECLEN=(2),                                     X
               AREALEN=(2),AREA=(3),MF=(G,(5))
         LTR   8,8
         BE    @@L3
         IC    3,21(9)
         LA    2,255(,3)
         CLM   2,1,=XL1'01'
         BH    @@L4
         MODCB RPL=(4),ARG=(8),MF=(G,(5))
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'00'
         BNE   @@L3
         L     2,16(11)
         MODCB RPL=(4),ARG=(8),KEYLEN=(2),MF=(G,(5))
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function __vsmdfy epilogue
         PDPEPIL
* Function __vsmdfy literal pool
         DS    0F
         LTORG
* Function __vsmdfy page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
