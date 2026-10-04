         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func iscntrl prologue
ISCNTRL  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function iscntrl code
         L     2,=V(@@ISBUF)
         L     3,0(2)
         L     2,0(11)
         SLL   2,1
         LH    15,0(2,3)
         N     15,=F'4'
* Function iscntrl epilogue
         PDPEPIL
* Function iscntrl literal pool
         DS    0F
         LTORG
* Function iscntrl page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
