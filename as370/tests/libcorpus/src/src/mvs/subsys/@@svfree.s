         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssvt_free'
* Program text area
         DS    0F
* X-func *@@SVFREE prologue
@@SVFREE PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SVFREE code
         L     15,0(11)
         SLR   4,4
         LTR   15,15
         BE    @@L1
         IPK   0             get psw key in R2
         LR    3,2           save psw key in register
         CLM   3,1,=XL1'00'
         BE    @@L3
         LA    4,1(0,0)
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L3     EQU   *
         L     12,0(,10)
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FREEMAIN)
         BALR  14,15
         LTR   4,4
         BE    @@L1
         LR    2,3               get prev psw key
         SPKA  0(2)             save in psw
@@L1     EQU   *
         L     12,0(,10)
* Function *@@SVFREE epilogue
         PDPEPIL
* Function *@@SVFREE literal pool
         DS    0F
         LTORG
* Function *@@SVFREE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
