         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssct_remove'
* Program text area
         DS    0F
* X-func *@@SSREM prologue
@@SSREM  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SSREM code
         L     5,0(11)
         MVC   88(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@SSFIND)
         BALR  14,15
         LA    4,4(0,0)
         IPK   0             get psw key in R2
         LR    3,2           save psw key in register
         CLM   3,1,=XL1'00'
         BE    @@L2
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L2     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L4
         L     2,4(15)
         CLR   2,5
         BNE   @@L5
         MVC   4(4,15),4(2)
         MVC   4(4,2),=F'0'
         SLR   4,4
         B     @@L4
@@L5     EQU   *
         L     12,0(,10)
         LR    15,2
         B     @@L2
@@L4     EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'00'
         BE    @@L7
         LR    2,3               get prev psw key
         SPKA  0(2)             save in psw
@@L7     EQU   *
         L     12,0(,10)
         LR    15,4
* Function *@@SSREM epilogue
         PDPEPIL
* Function *@@SSREM literal pool
         DS    0F
         LTORG
* Function *@@SSREM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
