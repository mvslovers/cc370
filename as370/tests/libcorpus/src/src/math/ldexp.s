         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ldexp prologue
LDEXP    PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ldexp code
         MVC   88(8,13),0(11)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(FREXP)
         BALR  14,15
         STD   0,80(,13)
         LM    4,5,80(13)
         L     3,104(13)
         A     3,8(11)
         ST    3,104(13)
         LR    2,3
         BNL   @@L2
         A     2,=F'3'
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
         SRA   15,2
         LR    2,15
         SLL   2,2
         LR    6,3
         SR    6,2
         BNL   @@L3
         BCTR  15,0
         A     6,=F'4'
@@L3     EQU   *
         L     12,0(,10)
         LR    2,4
         SRL   2,16
         SLL   2,16
         SRA   2,16
         N     2,=F'33023'
         SLL   2,16
         LR    3,4
         N     3,=F'65535'
         LR    4,3
         OR    4,2
         LR    3,4
         SRL   3,16
         A     15,=F'64'
         SLL   15,8
         LR    2,15
         SLL   2,16
         SRA   2,16
         N     2,=F'32512'
         OR    2,3
         SLL   2,16
         LR    3,4
         N     3,=F'65535'
         LR    4,3
         OR    4,2
@@L9     EQU   *
         LTR   6,6
         BNH   @@L8
         STM   4,5,80(13)
         LD    0,80(,13)
         ADR   0,0
         STD   0,80(,13)
         LM    4,5,80(13)
         BCTR  6,0
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
* Function ldexp epilogue
         PDPEPIL
* Function ldexp literal pool
         DS    0F
         LTORG
* Function ldexp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
