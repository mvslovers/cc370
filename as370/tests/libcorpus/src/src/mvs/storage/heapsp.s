         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'@PPA'
         DC    X'0'
         DS    0F
* Function heapppa,F6 prologue
@@F6     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function heapppa code
         SLR   4,4
         L     2,540(4)
         LR    15,2
         LTR   2,2
         BE    @@L1
         L     2,112(2)
         N     2,=F'16777215'
         LR    15,2
         LTR   2,2
         BE    @@L1
         L     3,8(2)
         LR    2,3
         BCTR  2,0
         LR    15,4
         L     5,=F'16777214'
         CLR   2,5
         BH    @@L1
         L     2,=A(@@LC0)
         CLC   0(4,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L1
         LR    15,3
@@L1     EQU   *
         L     12,0(,10)
* Function heapppa epilogue
         PDPEPIL
* Function heapppa literal pool
         DS    0F
         LTORG
* Function heapppa page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC '__setsp'
         DS    0F
* X-func __setsp prologue
@@SETSP  PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __setsp code
         L     3,0(11)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L6
         SLR   2,2
         IC    2,34(15)
         STC   3,34(15)
@@L6     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __setsp epilogue
         PDPEPIL
* Function __setsp literal pool
         DS    0F
         LTORG
* Function __setsp page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC '__getsp'
         DS    0F
* X-func __getsp prologue
@@GETSP  PDPPRLG CINDEX=2,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function __getsp code
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L10
         SLR   2,2
         IC    2,34(15)
@@L10    EQU   *
         L     12,0(,10)
         LR    15,2
* Function __getsp epilogue
         PDPEPIL
* Function __getsp literal pool
         DS    0F
         LTORG
* Function __getsp page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC '__getmsp'
         DS    0F
* X-func __getmsp prologue
@@GETMSP PDPPRLG CINDEX=3,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function __getmsp code
         L     5,0(11)
         SLR   6,6
         SLR   3,3
         IC    3,7(11)
         LR    2,5
         BCTR  2,0
         LR    15,6
         L     4,=F'16777214'
         CLR   2,4
         BH    @@L11
         A     5,=F'71'
         LR    4,5
         N     4,=F'-64'
         A     5,=F'-71'
         L     2,=F'16777215'
         CLR   4,2
         BH    @@L11
         GETMAIN RC,LV=(4),SP=(3)
         LR    2,15              save the return code
         LR    6,1               save the returned address
         SLR   15,15
         LTR   2,2
         BNE   @@L11
         SLL   3,24
         OR    3,4
         ST    3,0(6)
         ST    5,4(6)
         LR    15,6
         A     15,=F'8'
@@L11    EQU   *
         L     12,0(,10)
* Function __getmsp epilogue
         PDPEPIL
* Function __getmsp literal pool
         DS    0F
         LTORG
* Function __getmsp page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         END
