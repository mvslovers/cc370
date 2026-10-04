         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_detach'
* Program text area
         DS    0F
* X-func *@@CTDET prologue
@@CTDET  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTDET code
         L     3,0(11)
         SLR   15,15
         LTR   3,3
         BE    @@L3
         L     2,8(3)
         LTR   2,2
         BE    @@L3
         L     2,16(3)
         N     2,=F'1073741824'
         L     15,=F'-1'
         LTR   2,2
         BE    @@L3
         MVC   88(4,13),=A(@@F2)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         LTR   15,15
         BNE   @@L6
         L     15,20(3)
@@L6     EQU   *
         L     12,0(,10)
         MVC   8(4,3),=F'0'
@@L3     EQU   *
         L     12,0(,10)
* Function *@@CTDET epilogue
         PDPEPIL
* Function *@@CTDET literal pool
         DS    0F
         LTORG
* Function *@@CTDET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'detach'
         DS    0F
* Function detach,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function detach code
         L     4,0(11)
         MVC   88(4,13),8(4)
         LR    3,4
         A     3,=F'20'
         LA    2,88(,13)
         DS    0H
         DETACH (2),STAE=YES   detach the subtask
         ST    15,0(,3)          save the return code
         MVC   8(4,4),=F'0'
         L     15,0(3)
* Function detach epilogue
         PDPEPIL
* Function detach literal pool
         DS    0F
         LTORG
* Function detach page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
