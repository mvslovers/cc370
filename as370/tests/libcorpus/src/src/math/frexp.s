         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func frexp prologue
FREXP    PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function frexp code
         LD    2,0(11)
         L     15,8(11)
         LD    0,=D'0.0'
         LTDR  2,2
         BE    @@L1
         STD   2,80(,13)
         LM    4,5,80(13)
         STE   2,80(,13)
         L     3,80(,13)
         SRL   3,16
         SLL   3,16
         SRA   3,16
         LR    2,3
         N     2,=XL4'0000FFFF'
         SRL   2,8
         N     2,=F'127'
         SLL   2,2
         A     2,=F'-256'
         ST    2,0(15)
         N     3,=F'33023'
         SLL   3,16
         STE   2,80(,13)
         L     2,80(,13)
         N     2,=F'65535'
         LR    4,2
         OR    4,3
         LR    2,4
         SRL   2,16
         SLL   2,16
         SRA   2,16
         O     2,=F'16384'
         SLL   2,16
         LR    3,4
         N     3,=F'65535'
         LR    4,3
         OR    4,2
         STM   4,5,80(13)
         LD    2,80(,13)
         B     @@L11
@@L10    EQU   *
         LTDR  2,2
         BE    @@L5
         STM   4,5,80(13)
         LD    2,80(,13)
         ADR   2,2
         STD   2,80(,13)
         LM    4,5,80(13)
         L     2,0(15)
         BCTR  2,0
         ST    2,0(15)
@@L11    EQU   *
         L     12,0(,10)
         LPDR  0,2
         CD    0,=D'5.0E-1'
         BL    @@L10
@@L5     EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
@@L1     EQU   *
         L     12,0(,10)
* Function frexp epilogue
         PDPEPIL
* Function frexp literal pool
         DS    0F
         LTORG
* Function frexp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
