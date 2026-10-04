         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__autask'
* Program text area
         DS    0F
* X-func __autask prologue
@@AUTASK PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __autask code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         MVC   96(4,13),=F'0'
         TESTAUTH FCTN=1
         ST    15,96(13)
         L     2,96(13)
         LTR   2,2
         BE    @@L3
         MVC   88(4,13),=A(@@F2)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         TESTAUTH FCTN=1
         ST    15,96(13)
         L     2,96(13)
         LTR   2,2
         BNE   @@L3
         LTR   3,3
         BE    @@L3
         OI    269(3),128
@@L3     EQU   *
         L     12,0(,10)
         L     15,96(13)
* Function __autask epilogue
         PDPEPIL
* Function __autask literal pool
         DS    0F
         LTORG
* Function __autask page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'authorize'
         DS    0F
* Function authorize,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function authorize code
         SR    0,0
         LA    1,1
         SVC   244
* Function authorize epilogue
         PDPEPIL
* Function authorize literal pool
         DS    0F
         LTORG
* Function authorize page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         PRINT NOGEN
         IHAPSA ,            MAP LOW STORAGE
         CVT DSECT=YES
         IKJTCB DSECT=YES
         DCBD DSORG=PO,DEVD=DA
         IEZDEB
         PRINT GEN
         CSECT
         END
