         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memcpyp prologue
MEMCPYP  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memcpyp code
         L     7,0(11)
         L     6,4(11)
         L     15,12(11)
         L     8,16(11)
         LR    2,7
         CR    15,6
         BNH   @@L2
         LR    15,6
@@L2     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNH   @@L3
         LR    4,7
         LR    5,15
         L     2,8(11)
         LR    3,15
         MVCL  4,2
         LR    2,7
         AR    2,15
         SR    6,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNH   @@L4
         
*** MEMSET ***
         LR    14,2           => target (s)
         LR    15,6           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,8            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L4     EQU   *
         L     12,0(,10)
         LR    15,7
* Function memcpyp epilogue
         PDPEPIL
* Function memcpyp literal pool
         DS    0F
         LTORG
* Function memcpyp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
