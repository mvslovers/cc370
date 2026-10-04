         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__pswkey'
* Program text area
         DS    0F
* X-func __pswkey prologue
@@PSWKEY PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __pswkey code
         L     3,0(11)
         LA    1,88(,13)
         L     15,=V(@@ISAUTH)
         BALR  14,15
         LA    2,1(0,0)
         LTR   15,15
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L3
         IPK   0
         STC   2,0(,3)
         B     @@L4
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'255'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@SUPER)
         BALR  14,15
         MVC   88(4,13),=F'255'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@PROB)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         SLR   2,2
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __pswkey epilogue
         PDPEPIL
* Function __pswkey literal pool
         DS    0F
         LTORG
* Function __pswkey page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
