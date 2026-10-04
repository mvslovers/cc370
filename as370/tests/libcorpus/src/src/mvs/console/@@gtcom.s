         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __gtcom prologue
@@GTCOM  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __gtcom code
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LA    4,88(,13)
         LA    5,12(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         LR    2,15
         LTR   15,15
         BE    @@L1
         L     2,48(15)
         LTR   2,2
         BNE   @@L1
         LR    3,15
         A     3,=F'48'
         LA    2,88(,13)
         EXTRACT (3),FIELDS=COMM,MF=(E,(2))
         L     2,0(3)
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __gtcom epilogue
         PDPEPIL
* Function __gtcom literal pool
         DS    0F
         LTORG
* Function __gtcom page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
