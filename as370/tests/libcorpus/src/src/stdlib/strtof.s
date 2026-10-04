         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strtof prologue
STRTOF   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtof code
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(STRTOD)
         BALR  14,15
         LDR   2,0
         L     2,=V(@FLTMAX)
         LE    4,0(2)
         SDR   0,0
         LER   0,4
         CDR   2,0
         BNH   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         LE    0,0(2)
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LCER  0,4
         STE   0,80(,13)
         SDR   0,0
         LE    0,80(,13)
         CDR   2,0
         BNL   @@L4
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         LE    2,0(2)
         LCER  0,2
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         LRER  0,2
@@L1     EQU   *
         L     12,0(,10)
* Function strtof epilogue
         PDPEPIL
* Function strtof literal pool
         DS    0F
         LTORG
* Function strtof page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
