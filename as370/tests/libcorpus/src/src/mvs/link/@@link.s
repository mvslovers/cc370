         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __link prologue
@@LINK   PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __link code
         L     3,0(11)
         L     6,8(11)
         L     7,12(11)
         L     15,=F'-1'
         LTR   3,3
         BE    @@L3
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L3
         SLR   4,4
         LR    15,3
         LA    5,88(,13)
@@L8     EQU   *
         SLR   2,2
         IC    2,0(15)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     4,=F'1'
         A     5,=F'1'
         A     15,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BH    @@L6
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L8
@@L6     EQU   *
         L     12,0(,10)
         LA    2,7(0,0)
         CR    4,2
         BH    @@L15
         LA    2,64(0,0)
         STC   2,88(4,13)
         A     4,=F'1'
         B     @@L6
@@L15    EQU   *
         L     12,0(,10)
         MVI   96(13),0
         LA    2,88(,13)
         ST    2,104(13)
         MVC   108(4,13),4(11)
         LA    2,104(,13)
         OI    4(2),X'80'     extended plist for error ret address
         LA    0,ERRET         => error return address
         ST    0,8(0,2)       save in LINK SVC parameter list
         LR    1,6            => linked program parameter list
         LR    15,2           => LINK SVC parameter list
         SVC   6              LINK SVC
         B     DONE             normal return, return to caller
ERRET    DS    0H
         L     15,=F'-1'        indicate failure
DONE     DS    0H
         LR    15,15           save return code
@@L3     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L12
         ST    15,0(7)
@@L12    EQU   *
         L     12,0(,10)
* Function __link epilogue
         PDPEPIL
* Function __link literal pool
         DS    0F
         LTORG
* Function __link page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
