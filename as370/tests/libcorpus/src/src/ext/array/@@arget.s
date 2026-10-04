         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arrayget'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARGET prologue
@@ARGET  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARGET code
         L     2,0(11)
         L     3,4(11)
         SLR   15,15
         LTR   2,2
         BE    @@L6
         L     4,0(2)
         LTR   4,4
         BE    @@L6
         LR    5,4
         A     5,=F'-12'
         L     2,=A(@@LC0)
         CLC   0(4,5),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L6
         LTR   3,3
         BE    @@L6
         CL    3,8(5)
         BH    @@L6
         SLL   3,2
         AR    3,4
         A     3,=F'-4'
         L     15,0(3)
@@L6     EQU   *
         L     12,0(,10)
* Function *@@ARGET epilogue
         PDPEPIL
* Function *@@ARGET literal pool
         DS    0F
         LTORG
* Function *@@ARGET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
