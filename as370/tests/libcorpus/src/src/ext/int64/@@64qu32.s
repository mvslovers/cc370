         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_mod_u32'
* Program text area
         DS    0F
* X-func *@@64QU32 prologue
@@64QU32 PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64QU32 code
         L     3,0(11)
         L     4,8(11)
         LTR   3,3
         BE    @@L1
         LTR   4,4
         BE    @@L1
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         ST    3,88(13)
         ST    2,92(13)
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MOD)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64QU32 epilogue
         PDPEPIL
* Function *@@64QU32 literal pool
         DS    0F
         LTORG
* Function *@@64QU32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
