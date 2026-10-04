         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'utime64'
* Program text area
         DS    0F
* X-func *TM64UTIM prologue
TM64UTIM PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64UTIM code
         LR    4,0
         L     5,0(11)
         LA    0,88(,13)
         LA    1,88(,13)
         L     15,=V(TM64UCLK)
         BALR  14,15
         L     2,88(13)
         L     3,4+88(13)
         LTR   5,5
         BE    @@L2
         ST    2,0(5)
         ST    3,4+0(5)
@@L2     EQU   *
         L     12,0(,10)
         ST    2,0(4)
         ST    3,4+0(4)
         LR    15,4
* Function *TM64UTIM epilogue
         PDPEPIL
* Function *TM64UTIM literal pool
         DS    0F
         LTORG
* Function *TM64UTIM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
