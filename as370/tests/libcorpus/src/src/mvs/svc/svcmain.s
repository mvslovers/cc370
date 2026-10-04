         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *SVCMAIN prologue
SVCMAIN  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *SVCMAIN code
         L     4,0(11)
         L     5,4(11)
         L     15,32(4)
         L     3,8(4)
         LA    2,4(0,0)
         CLR   3,2
         BH    @@L10
         SLL   3,2
         L     2,=A(@@L11)
         L     14,0(3,2)
         BR    14
         DS    0F
         DS    0F
         DS    0F
         LTORG
         DS    0F
@@L11    EQU   *
         DC    A(@@L3)
         DC    A(@@L4)
         DC    A(@@L5)
         DC    A(@@L8)
         DC    A(@@L9)
@@L3     EQU   *
         L     12,0(,10)
         IC    2,17(15)
         X     2,=F'-1'
         N     2,=F'1'
         ST    2,0(5)
         NI    17(15),254
         B     @@L2
@@L4     EQU   *
         L     12,0(,10)
         IC    2,17(15)
         N     2,=F'1'
         ST    2,0(5)
         OI    17(15),1
         B     @@L2
@@L5     EQU   *
         L     12,0(,10)
         IC    2,17(15)
         N     2,=F'240'
         ST    2,0(5)
         CLI   3(4),255
         BE    @@L2
         IC    3,17(15)
         N     3,=F'15'
         STC   3,17(15)
         IC    2,3(4)
         N     2,=F'-16'
         OR    3,2
         STC   3,17(15)
         B     @@L2
@@L8     EQU   *
         L     12,0(,10)
         L     3,36(4)
         IC    2,236(3)
         N     2,=F'1'
         ST    2,0(5)
         OI    236(3),1
         B     @@L2
@@L9     EQU   *
         L     12,0(,10)
         L     3,36(4)
         IC    2,236(3)
         X     2,=F'-1'
         N     2,=F'1'
         ST    2,0(5)
         NI    236(3),254
         B     @@L2
@@L10    EQU   *
         L     12,0(,10)
         MVC   0(4,5),=F'-1'
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function *SVCMAIN epilogue
         PDPEPIL
* Function *SVCMAIN literal pool
         DS    0F
         LTORG
* Function *SVCMAIN page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
