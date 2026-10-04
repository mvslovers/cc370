         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesirput prologue
JESIRPUT PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesirput code
         L     3,0(11)
         L     15,4(11)
         MVC   104(4,13),=F'-1'
         LTR   15,15
         BE    @@L4
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L4
         LTR   3,3
         BNE   @@L5
         MVC   104(4,13),=F'-2'
         B     @@L4
@@L5     EQU   *
         L     12,0(,10)
         OI    17(3),32
         MVC   88(4,13),136(3)
         MVC   92(4,13),=F'80'
         ST    15,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         A     3,=F'104'
         PUT RPL=(3)
         ST  15,104(13)
@@L4     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function jesirput epilogue
         PDPEPIL
* Function jesirput literal pool
         DS    0F
         LTORG
* Function jesirput page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
