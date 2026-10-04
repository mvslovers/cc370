         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arrayfree'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARFRE prologue
@@ARFRE  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARFRE code
         L     4,0(11)
         SLR   3,3
         LTR   4,4
         BE    @@L6
         L     2,0(4)
         LTR   2,2
         BE    @@L6
         LR    15,2
         A     15,=F'-12'
         L     2,=A(@@LC0)
         CLC   0(4,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L5
@@L6     EQU   *
         L     12,0(,10)
         L     3,=F'-1'
         B     @@L3
@@L5     EQU   *
         L     12,0(,10)
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         ST    3,0(4)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@ARFRE epilogue
         PDPEPIL
* Function *@@ARFRE literal pool
         DS    0F
         LTORG
* Function *@@ARFRE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
