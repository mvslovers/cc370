         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssvt_funcmap'
* Program text area
         DS    0F
* X-func *@@SVFMAP prologue
@@SVFMAP PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SVFMAP code
         L     6,0(11)
         L     5,4(11)
         L     3,8(11)
         SLR   4,4
         LA    15,1(0,0)
         LTR   6,6
         BE    @@L1
         LA    2,256(0,0)
         CLR   5,2
         BH    @@L1
         LTR   3,3
         BE    @@L1
         CLR   3,2
         BH    @@L1
         BCTR  3,0
         IPK   0             get psw key in R2
         LR    15,2           save psw key in register
         CLM   15,1,=XL1'00'
         BE    @@L6
         LA    4,1(0,0)
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L6     EQU   *
         L     12,0(,10)
         STC   5,4(3,6)
         LTR   4,4
         BE    @@L7
         LR    2,15               get prev psw key
         SPKA  0(2)             save in psw
@@L7     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function *@@SVFMAP epilogue
         PDPEPIL
* Function *@@SVFMAP literal pool
         DS    0F
         LTORG
* Function *@@SVFMAP page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
