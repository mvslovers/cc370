         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __uatask prologue
@@UATASK PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __uatask code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         IC    2,269(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L3
         MVC   88(4,13),=A(@@F2)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         NI    269(3),127
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function __uatask epilogue
         PDPEPIL
* Function __uatask literal pool
         DS    0F
         LTORG
* Function __uatask page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'unauthorize'
         DS    0F
* Function unauthorize,F2 prologue
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
* Function unauthorize code
         SR    0,0
         SR    1,1
         SVC   244
* Function unauthorize epilogue
         PDPEPIL
* Function unauthorize literal pool
         DS    0F
         LTORG
* Function unauthorize page table
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
