         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_mod'
* Program text area
         DS    0F
* X-func *@@64MOD prologue
@@64MOD  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64MOD code
         L     2,0(11)
         L     15,4(11)
         L     3,8(11)
         LTR   2,2
         BE    @@L1
         LTR   15,15
         BE    @@L1
         LTR   3,3
         BE    @@L1
         ST    2,88(13)
         ST    15,92(13)
         LA    2,104(,13)
         ST    2,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@64DMOD)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64MOD epilogue
         PDPEPIL
* Function *@@64MOD literal pool
         DS    0F
         LTORG
* Function *@@64MOD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
