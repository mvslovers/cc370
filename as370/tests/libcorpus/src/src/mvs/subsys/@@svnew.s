         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssvt_new'
* Program text area
         DS    0F
* X-func *@@SVNEW prologue
@@SVNEW  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SVNEW code
         L     4,0(11)
         SLR   5,5
         LR    15,5
         LA    2,256(0,0)
         CLR   4,2
         BH    @@L1
         IPK   0             get psw key in R2
         LR    3,2           save psw key in register
         CLM   3,1,=XL1'00'
         BE    @@L3
         LA    5,1(0,0)
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L3     EQU   *
         L     12,0(,10)
         LR    2,4
         SLL   2,2
         A     2,=F'260'
         ST    2,88(13)
         MVC   92(4,13),=F'241'
         LA    1,88(,13)
         L     15,=V(GETMAIN)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         STH   4,2(15)
@@L4     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L1
         LR    2,3               get prev psw key
         SPKA  0(2)             save in psw
@@L1     EQU   *
         L     12,0(,10)
* Function *@@SVNEW epilogue
         PDPEPIL
* Function *@@SVNEW literal pool
         DS    0F
         LTORG
* Function *@@SVNEW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
