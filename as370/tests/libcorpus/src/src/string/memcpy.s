         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memcpy prologue
MEMCPY   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memcpy code
         
         L    14,0(11)    => target (s1)
         L    15,8(11)    => length (n)
         L    0,4(11)     => source (s2)
         L    1,8(11)     => length (n)
         MVCL 14,0     Copy source to target
         L     15,0(11)
* Function memcpy epilogue
         PDPEPIL
* Function memcpy literal pool
         DS    0F
         LTORG
* Function memcpy page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
