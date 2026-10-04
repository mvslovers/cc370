         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_div_i32'
* Program text area
         DS    0F
* X-func *@@64DI32 prologue
@@64DI32 PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64DI32 code
         L     4,0(11)
         L     6,4(11)
         L     5,8(11)
         LTR   4,4
         BE    @@L1
         LTR   5,5
         BE    @@L1
         LA    3,104(,13)
         ST    3,88(13)
         LPR   2,6
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         LTR   6,6
         BNL   @@L4
         ST    4,88(13)
         ST    3,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MUL)
         BALR  14,15
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         ST    3,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64DIV)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64DI32 epilogue
         PDPEPIL
* Function *@@64DI32 literal pool
         DS    0F
         LTORG
* Function *@@64DI32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
