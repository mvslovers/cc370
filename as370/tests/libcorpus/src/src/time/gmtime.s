         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func gmtime prologue
GMTIME   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function gmtime code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L1
         A     15,=F'296'
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(GMTIMER)
         BALR  14,15
         LR    2,15
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function gmtime epilogue
         PDPEPIL
* Function gmtime literal pool
         DS    0F
         LTORG
* Function gmtime page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
