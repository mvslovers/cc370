         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'SSOB'
         DC    X'0'
         DS    0F
* X-func initssob prologue
INITSSOB PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function initssob code
         L     3,0(11)
         SLR   4,4
         LA    2,20(0,0)
         
*** MEMSET ***
         LR    14,3           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,4            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         L     2,=A(@@LC0)
         MVC   0(4,3),0(2)
         MVC   4(2,3),=H'20'
         MVC   16(4,3),4(11)
         LR    15,4
* Function initssob epilogue
         PDPEPIL
* Function initssob literal pool
         DS    0F
         LTORG
* Function initssob page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
