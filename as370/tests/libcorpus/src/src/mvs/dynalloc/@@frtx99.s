         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __frtx99 prologue
@@FRTX99 PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __frtx99 code
         L     2,0(11)
         LTR   2,2
         BE    @@L1
         L     15,0(2)
         LTR   15,15
         BE    @@L1
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,2),=F'0'
@@L1     EQU   *
         L     12,0(,10)
* Function __frtx99 epilogue
         PDPEPIL
* Function __frtx99 literal pool
         DS    0F
         LTORG
* Function __frtx99 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
