         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strncpy prologue
STRNCPY  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strncpy code
         L     15,0(11)
         L     5,4(11)
         L     6,8(11)
         LR    4,15
         SLR   3,3
@@L14    EQU   *
         CLR   3,6
         BNL   @@L3
         MVC   0(1,4),0(5)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L3
         A     4,=F'1'
         A     5,=F'1'
         A     3,=F'1'
         B     @@L14
@@L3     EQU   *
         L     12,0(,10)
         CLR   3,6
         BNL   @@L13
@@L10    EQU   *
         MVI   0(4),0
         A     4,=F'1'
         A     3,=F'1'
         CLR   3,6
         BL    @@L10
@@L13    EQU   *
         L     12,0(,10)
* Function strncpy epilogue
         PDPEPIL
* Function strncpy literal pool
         DS    0F
         LTORG
* Function strncpy page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
