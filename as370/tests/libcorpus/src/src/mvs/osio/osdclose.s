         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osdclose prologue
OSDCLOSE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osdclose code
         L     3,0(11)
         LTR   3,3
         BE    @@L1
         LR    2,3
         O     2,=F'-2147483648'
         ST    2,96(13)
         LA    2,96(,13)
         LR    1,2
         SVC   20         CLOSE
         L     2,4(11)
         LTR   2,2
         BE    @@L1
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function osdclose epilogue
         PDPEPIL
* Function osdclose literal pool
         DS    0F
         LTORG
* Function osdclose page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
