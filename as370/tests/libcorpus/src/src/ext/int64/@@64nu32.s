         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_and_u32'
* Program text area
         DS    0F
* X-func *@@64NU32 prologue
@@64NU32 PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64NU32 code
         L     4,0(11)
         L     6,8(11)
         LTR   4,4
         BE    @@L1
         LTR   6,6
         BE    @@L1
         LA    2,96(,13)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         L     2,0(4)
         L     3,4+0(4)
         L     4,96(13)
         L     5,4+96(13)
         NR    2,4
         NR    3,5
         ST    2,0(6)
         ST    3,4+0(6)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64NU32 epilogue
         PDPEPIL
* Function *@@64NU32 literal pool
         DS    0F
         LTORG
* Function *@@64NU32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
