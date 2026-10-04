         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memset prologue
MEMSET   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memset code
         
         L    14,0(11)    => target (s)
         L    15,8(11)    => length (n)
         SLR  0,0      => source (NULL)
         L    1,4(11)     => fill (c)
         SLL  1,24     move fill char to high byte
         MVCL 14,0     Set target to fill character
         L     15,0(11)
* Function memset epilogue
         PDPEPIL
* Function memset literal pool
         DS    0F
         LTORG
* Function memset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
