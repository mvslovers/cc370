         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __cpclos prologue
@@CPCLOS PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cpclos code
         L     3,0(11)
         LTR   3,3
         BE    @@L2
         L     15,16(3)
         MVC   96(4,13),=F'-2147483648'
         IC    2,48(15)
         N     2,=F'16'
         LTR   2,2
         BE    @@L3
         LA    2,96(,13)
         CLOSE ((15)),MF=(E,(2))
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         L     2,236(3)
         LTR   2,2
         BE    @@L4
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function __cpclos epilogue
         PDPEPIL
* Function __cpclos literal pool
         DS    0F
         LTORG
* Function __cpclos page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'deallocate_checkpoint'
         DS    0F
* Function deallocate_checkpoint,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=128,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function deallocate_checkpoint code
         L     2,0(11)
         SLR   15,15
         ST    15,120(13)
         LA    6,96(,13)
         LA    7,20(0,0)
         LR    4,15
         LR    5,15
         MVCL  6,4
         LA    4,120(,13)
         ST    4,88(13)
         A     2,=F'8'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDDN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L7
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         LR    2,15
         BCTR  2,0
         L     4,120(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),2
         MVI   98(13),64
         MVC   104(4,13),120(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
@@L7     EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L9
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         LR    15,3
* Function deallocate_checkpoint epilogue
         PDPEPIL
* Function deallocate_checkpoint literal pool
         DS    0F
         LTORG
* Function deallocate_checkpoint page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
