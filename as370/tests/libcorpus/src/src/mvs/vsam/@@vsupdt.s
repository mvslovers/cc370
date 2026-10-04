         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsupdt prologue
@@VSUPDT PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsupdt code
         L     3,0(11)
         L     5,4(11)
         L     4,8(11)
         LA    8,88(,13)
         LA    9,64(0,0)
         SLR   6,6
         LR    7,6
         MVCL  8,6
         MVC   152(4,13),=F'0'
         A     3,=F'104'
         LA    2,88(,13)
         
         MODCB RPL=(3),RECLEN=(4),                                     X
               AREALEN=(4),AREA=(5),MF=(G,(2))
         LA    2,PUTDONE
         PUT   RPL=(3)
PUTDONE  DS    0H
         ST    15,152(13)
@@L2     EQU   *
         L     15,152(13)
* Function __vsupdt epilogue
         PDPEPIL
* Function __vsupdt literal pool
         DS    0F
         LTORG
* Function __vsupdt page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
