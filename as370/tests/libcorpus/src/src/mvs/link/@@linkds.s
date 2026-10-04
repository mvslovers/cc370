         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'trylink'
* Program text area
         DS    0F
* Function trylink,F1 prologue
@@F1     PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function trylink code
         SLR   2,2
         ST    2,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ABRPT)
         BALR  14,15
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         MVC   100(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(@@LINK)
         BALR  14,15
         LR    2,15
         MVC   88(4,13),=F'2'
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ABRPT)
         BALR  14,15
         LR    15,2
* Function trylink epilogue
         PDPEPIL
* Function trylink literal pool
         DS    0F
         LTORG
* Function trylink page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func __linkds prologue
@@LINKDS PDPPRLG CINDEX=1,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __linkds code
         MVC   88(4,13),=A(@@F1)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         MVC   104(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
* Function __linkds epilogue
         PDPEPIL
* Function __linkds literal pool
         DS    0F
         LTORG
* Function __linkds page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
