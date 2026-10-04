         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func atan2 prologue
ATAN2    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function atan2 code
         LD    2,0(11)
         LD    0,8(11)
         LCDR  4,2
         CDR   0,2
         BL    @@L2
         CDR   0,4
         BL    @@L5
         DDR   2,0
         STD   2,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LDR   2,0
         B     @@L3
@@L5     EQU   *
         L     12,0(,10)
         DDR   0,2
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LD    2,=D'-1.57079632679489655799898E+0'
         B     @@L14
@@L2     EQU   *
         L     12,0(,10)
         CDR   0,4
         BL    @@L8
         DDR   0,2
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LD    2,=D'1.57079632679489655799898E+0'
@@L14    EQU   *
         L     12,0(,10)
         SDR   2,0
         B     @@L3
@@L8     EQU   *
         L     12,0(,10)
         LDR   4,2
         DDR   4,0
         LTDR  2,2
         BL    @@L11
         STD   4,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LDR   2,0
         AD    2,=D'3.14159265358979333804257E+0'
         B     @@L3
@@L11    EQU   *
         L     12,0(,10)
         STD   4,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LDR   2,0
         AD    2,=D'-3.14159265358979333804257E+0'
@@L3     EQU   *
         L     12,0(,10)
         LDR   0,2
* Function atan2 epilogue
         PDPEPIL
* Function atan2 literal pool
         DS    0F
         LTORG
* Function atan2 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
