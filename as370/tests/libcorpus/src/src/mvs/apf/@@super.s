         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__super'
* Program text area
         DS    0F
* X-func __super prologue
@@SUPER  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __super code
         L     3,4(11)
         MVC   92(1,13),3(11)
         MVC   88(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ISAUTH)
         BALR  14,15
         LA    2,1(0,0)
         LTR   15,15
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         LA    2,88(,13)
         MODESET MODE=SUP
         ST    15,0(,2)
         L     2,88(13)
         LTR   2,2
         BNE   @@L5
@@L3     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L6
         IPK   0
         STC   2,0(,3)
@@L6     EQU   *
         L     12,0(,10)
         IC    2,92(13)
         CLM   2,1,=XL1'FF'
         BE    @@L5
         CLM   2,1,=XL1'0F'
         BH    @@L8
         SLL   2,4
         STC   2,92(13)
@@L8     EQU   *
         L     12,0(,10)
         LA    3,92(,13)
         IC    2,0(,3)
         SPKA  0(2)
@@L5     EQU   *
         L     12,0(,10)
         L     2,88(13)
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __super epilogue
         PDPEPIL
* Function __super literal pool
         DS    0F
         LTORG
* Function __super page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
