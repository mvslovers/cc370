         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __tzset prologue
@@TZSET  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __tzset code
         LA    2,1(0,0)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         MVC   52(4,15),0(11)
         SLR   2,2
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __tzset epilogue
         PDPEPIL
* Function __tzset literal pool
         DS    0F
         LTORG
* Function __tzset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
