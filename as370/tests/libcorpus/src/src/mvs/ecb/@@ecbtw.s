         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ecb_timed_wait'
* Program text area
         DS    0F
* X-func *@@ECBTW prologue
@@ECBTW  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ECBTW code
         L     3,0(11)
         LR    2,3
         O     2,=F'-2147483648'
         ST    2,104(13)
         LA    2,104(,13)
         ST    2,88(13)
         ST    3,92(13)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@ECBTWL)
         BALR  14,15
* Function *@@ECBTW epilogue
         PDPEPIL
* Function *@@ECBTW literal pool
         DS    0F
         LTORG
* Function *@@ECBTW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
