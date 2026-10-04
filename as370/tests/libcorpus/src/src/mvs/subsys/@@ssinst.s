         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssct_install'
* Program text area
         DS    0F
* X-func *@@SSINST prologue
@@SSINST PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SSINST code
         L     4,0(11)
         MVC   88(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@SSFIND)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@SSFIND)
         BALR  14,15
@@L9     EQU   *
         L     2,4(15)
         LTR   2,2
         BE    @@L2
         L     15,4(15)
         B     @@L9
@@L2     EQU   *
         IPK   0             get psw key in R2
         LR    3,2           save psw key in register
         L     12,0(,10)
         CLM   3,1,=XL1'00'
         BE    @@L6
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L6     EQU   *
         L     12,0(,10)
         MVC   4(4,4),4(15)
         ST    4,4(15)
         CLM   3,1,=XL1'00'
         BE    @@L7
         LR    2,3               get prev psw key
         SPKA  0(2)             save in psw
@@L7     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function *@@SSINST epilogue
         PDPEPIL
* Function *@@SSINST literal pool
         DS    0F
         LTORG
* Function *@@SSINST page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
