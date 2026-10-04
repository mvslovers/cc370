         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *LOCALTMR prologue
LOCALTMR PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *LOCALTMR code
         LA    1,88(,13)
         L     15,=V(@@TZGET)
         BALR  14,15
         L     2,0(11)
         L     2,0(2)
         AR    2,15
         ST    2,96(13)
         LA    2,96(,13)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(GMTIMER)
         BALR  14,15
* Function *LOCALTMR epilogue
         PDPEPIL
* Function *LOCALTMR literal pool
         DS    0F
         LTORG
* Function *LOCALTMR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
