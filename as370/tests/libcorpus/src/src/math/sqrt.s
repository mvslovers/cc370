         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func sqrt prologue
SQRT     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function sqrt code
         LD    2,0(11)
         LTDR  2,2
         BNL   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'33'
         LD    0,=D'0.0'
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LD    0,=D'0.0'
         LTDR  2,2
         BE    @@L1
         LDR   6,2
         LM    4,5,=D'1.0E+0'
@@L25    EQU   *
         CD    6,=D'1.0E+0'
         BNL   @@L22
         MD    6,=D'4.0E+0'
         STM   4,5,80(13)
         LD    0,80(,13)
         MD    0,=D'5.0E-1'
         STD   0,80(,13)
         LM    4,5,80(13)
         B     @@L25
@@L22    EQU   *
         L     12,0(,10)
         CD    6,=D'4.0E+0'
         BL    @@L24
         MD    6,=D'2.5E-1'
         STM   4,5,80(13)
         LD    2,80(,13)
         STM   4,5,80(13)
         LD    0,80(,13)
         ADR   2,0
         STD   2,80(,13)
         LM    4,5,80(13)
         B     @@L22
@@L24    EQU   *
         L     12,0(,10)
         SLR   15,15
         LDR   0,6
         MD    0,=D'5.0E-1'
@@L14    EQU   *
         LDR   4,6
         DDR   4,0
         ADR   4,0
         MD    4,=D'5.0E-1'
         LDR   2,4
         SDR   2,0
         LPDR  0,2
         L     2,=V(@DBLMIN)
         SDR   2,2
         LE    2,0(2)
         MD    2,=D'1.0E+1'
         CDR   0,2
         BNH   @@L15
         LDR   0,4
         LA    2,10(0,0)
         CR    15,2
         BH    @@L15
         A     15,=F'1'
         B     @@L14
@@L15    EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
         MDR   0,4
@@L1     EQU   *
         L     12,0(,10)
* Function sqrt epilogue
         PDPEPIL
* Function sqrt literal pool
         DS    0F
         LTORG
* Function sqrt page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
