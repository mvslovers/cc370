         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vswrit prologue
@@VSWRIT PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vswrit code
         L     6,0(11)
         LA    4,112(,13)
         LA    5,64(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         MVC   176(4,13),=F'0'
         ST    6,88(13)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         MVC   100(4,13),12(11)
         MVC   104(4,13),16(11)
         LA    1,88(,13)
         L     15,=V(@@VSMDFY)
         BALR  14,15
         OI    17(6),32
         IC    3,23(6)
         CLM   3,1,=XL1'02'
         BNE   @@L2
         A     6,=F'104'
         LA    2,112(,13)
         MODCB RPL=(6),OPTCD=(NUP),MF=(G,(2))
         A     6,=F'-104'
         MVC   184(4,6),=A(@@F2)
@@L2     EQU   *
         L     12,0(,10)
         A     6,=F'104'
         LA    2,PUTDONE
         PUT   RPL=(6)
PUTDONE  DS    0H
         ST    15,176(13)
         A     6,=F'-104'
         CLM   3,1,=XL1'02'
         BNE   @@L4
         L     2,184(6)
         LTR   2,2
         BE    @@L4
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         L     15,176(13)
* Function __vswrit epilogue
         PDPEPIL
* Function __vswrit literal pool
         DS    0F
         LTORG
* Function __vswrit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function restore,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=152,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function restore code
         L     3,0(11)
         LA    6,88(,13)
         LA    7,64(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         A     3,=F'104'
         LA    2,88(,13)
         MODCB RPL=(3),OPTCD=(UPD),MF=(G,(2))
         A     3,=F'-104'
         MVC   184(4,3),=F'0'
         SLR   15,15
* Function restore epilogue
         PDPEPIL
* Function restore literal pool
         DS    0F
         LTORG
* Function restore page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
