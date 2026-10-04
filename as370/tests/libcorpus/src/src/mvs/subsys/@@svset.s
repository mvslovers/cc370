         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssvt_set'
* Program text area
         DS    0F
* X-func *@@SVSET prologue
@@SVSET  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SVSET code
         L     5,0(11)
         L     3,4(11)
         SLR   4,4
         LA    15,1(0,0)
         LTR   5,5
         BE    @@L1
         LTR   3,3
         BE    @@L1
         LA    2,256(0,0)
         CLR   3,2
         BH    @@L1
         BCTR  3,0
         IPK   0             get psw key in R2
         LR    15,2           save psw key in register
         CLM   15,1,=XL1'00'
         BE    @@L5
         LA    4,1(0,0)
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L5     EQU   *
         L     12,0(,10)
         SLL   3,2
         L     2,8(11)
         ST    2,260(5,3)
         LTR   4,4
         BE    @@L6
         LR    2,15               get prev psw key
         SPKA  0(2)             save in psw
@@L6     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function *@@SVSET epilogue
         PDPEPIL
* Function *@@SVSET literal pool
         DS    0F
         LTORG
* Function *@@SVSET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
