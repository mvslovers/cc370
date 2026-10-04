         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strcpyp prologue
STRCPYP  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strcpyp code
         L     8,0(11)
         L     6,4(11)
         L     7,8(11)
         L     9,12(11)
         LR    2,8
         LR    15,7
         LTR   7,7
         BE    @@L3
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         CR    15,6
         BNH   @@L4
         LR    15,6
@@L4     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNH   @@L5
         LR    4,8
         LR    5,15
         LR    2,7
         LR    3,15
         MVCL  4,2
         LR    2,8
         AR    2,15
         SR    6,15
@@L5     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNH   @@L6
         
*** MEMSET ***
         LR    14,2           => target (s)
         LR    15,6           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,9            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L6     EQU   *
         L     12,0(,10)
         LR    15,8
* Function strcpyp epilogue
         PDPEPIL
* Function strcpyp literal pool
         DS    0F
         LTORG
* Function strcpyp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
