         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __sigdfl prologue
@@SIGDFL PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __sigdfl code
         L     3,0(11)
         LR    2,3
         BCTR  2,0
         LA    4,5(0,0)
         CLR   2,4
         BH    @@L2
         LA    1,88(,13)
         L     15,=V(@@SIGHDL)
         BALR  14,15
         LR    2,3
         SLL   2,2
         L     4,=A(@@SIGDFL)
         ST    4,0(2,15)
@@L2     EQU   *
         L     12,0(,10)
         LA    2,1(0,0)
         CLR   3,2
         BNE   @@L1
         MVC   88(4,13),=F'12'
         LA    1,88(,13)
         L     15,=V(EXIT)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function __sigdfl epilogue
         PDPEPIL
* Function __sigdfl literal pool
         DS    0F
         LTORG
* Function __sigdfl page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
