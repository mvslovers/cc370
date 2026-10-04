         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ftell prologue
FTELL    PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ftell code
         L     3,0(11)
         LH    2,40(3)
         N     2,=F'32'
         LTR   2,2
         BE    @@L2
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(FSEEK)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         L     15,24(3)
* Function ftell epilogue
         PDPEPIL
* Function ftell literal pool
         DS    0F
         LTORG
* Function ftell page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
