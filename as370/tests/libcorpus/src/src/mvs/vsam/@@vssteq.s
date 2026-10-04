         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vssteq prologue
@@VSSTEQ PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vssteq code
         L     3,0(11)
         LA    6,112(,13)
         LA    7,64(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         MVC   176(4,13),=F'0'
         ST    3,88(13)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         MVC   100(4,13),12(11)
         MVC   104(4,13),16(11)
         LA    1,88(,13)
         L     15,=V(@@VSMDFY)
         BALR  14,15
         MVC   184(4,3),=F'0'
         A     3,=F'104'
         LA    2,112(,13)
         MODCB RPL=(3),OPTCD=(KEQ),MF=(G,(2))
         LA    2,DONE
         POINT RPL=(3)
DONE     DS    0H
         ST    15,176(13)
@@L2     EQU   *
         L     15,176(13)
* Function __vssteq epilogue
         PDPEPIL
* Function __vssteq literal pool
         DS    0F
         LTORG
* Function __vssteq page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
