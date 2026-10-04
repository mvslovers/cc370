         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arraydel'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARDEL prologue
@@ARDEL  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARDEL code
         L     7,0(11)
         L     3,4(11)
         SLR   15,15
         LTR   7,7
         BE    @@L10
         L     5,0(7)
         LTR   5,5
         BE    @@L10
         LR    4,5
         A     4,=F'-12'
         L     2,=A(@@LC0)
         CLC   0(4,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L10
         LTR   3,3
         BE    @@L10
         L     6,8(4)
         CLR   3,6
         BH    @@L10
         BCTR  3,0
         LR    2,3
         SLL   2,2
         L     15,0(2,5)
         CLR   3,6
         BNL   @@L12
@@L9     EQU   *
         LR    2,3
         SLL   2,2
         A     2,0(7)
         MVC   0(4,2),4(2)
         A     3,=F'1'
         CL    3,8(4)
         BL    @@L9
@@L12    EQU   *
         L     12,0(,10)
         L     2,8(4)
         BCTR  2,0
         ST    2,8(4)
         L     3,0(7)
         SLL   2,2
         SLR   4,4
         ST    4,0(2,3)
@@L10    EQU   *
         L     12,0(,10)
* Function *@@ARDEL epilogue
         PDPEPIL
* Function *@@ARDEL literal pool
         DS    0F
         LTORG
* Function *@@ARDEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
