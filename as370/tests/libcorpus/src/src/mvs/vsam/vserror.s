         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func vserror prologue
VSERROR  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vserror code
         L     2,0(11)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@VSERR)
         BALR  14,15
         LR    3,15
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,3
* Function vserror epilogue
         PDPEPIL
* Function vserror literal pool
         DS    0F
         LTORG
* Function vserror page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
