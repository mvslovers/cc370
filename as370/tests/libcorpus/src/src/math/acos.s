         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func acos prologue
ACOS     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function acos code
         LD    2,0(11)
         LPDR  0,2
         CD    0,=D'1.0E+0'
         BNH   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'33'
         LD    2,=D'9.999999999999999830337E+72'
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LTDR  2,2
         BNL   @@L4
         LCDR  0,2
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ACOS)
         BALR  14,15
         LD    2,=D'3.14159265358979333804257E+0'
         SDR   2,0
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         MDR   2,2
         LD    0,=D'1.0E+0'
         SDR   0,2
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(SQRT)
         BALR  14,15
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ASIN)
         BALR  14,15
         LDR   2,0
@@L1     EQU   *
         L     12,0(,10)
         LDR   0,2
* Function acos epilogue
         PDPEPIL
* Function acos literal pool
         DS    0F
         LTORG
* Function acos page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
