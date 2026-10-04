         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arraycount'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARCOU prologue
@@ARCOU  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARCOU code
         L     2,0(11)
         SLR   15,15
         LTR   2,2
         BE    @@L5
         L     2,0(2)
         LTR   2,2
         BE    @@L5
         LR    3,2
         A     3,=F'-12'
         L     2,=A(@@LC0)
         CLC   0(4,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         L     15,8(3)
@@L5     EQU   *
         L     12,0(,10)
* Function *@@ARCOU epilogue
         PDPEPIL
* Function *@@ARCOU literal pool
         DS    0F
         LTORG
* Function *@@ARCOU page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
