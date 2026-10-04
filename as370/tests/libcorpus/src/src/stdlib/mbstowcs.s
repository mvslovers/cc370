         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mbstowcs prologue
MBSTOWCS PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mbstowcs code
         L     4,0(11)
         L     2,4(11)
         L     5,8(11)
         LTR   4,4
         BNE   @@L2
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
         CLR   15,5
         BNL   @@L9
         LR    3,2
@@L7     EQU   *
         SLR   2,2
         IC    2,0(3)
         ST    2,0(4)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L1
         A     15,=F'1'
         A     4,=F'4'
         A     3,=F'1'
         CLR   15,5
         BL    @@L7
@@L9     EQU   *
         L     12,0(,10)
         LR    15,5
@@L1     EQU   *
         L     12,0(,10)
* Function mbstowcs epilogue
         PDPEPIL
* Function mbstowcs literal pool
         DS    0F
         LTORG
* Function mbstowcs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
