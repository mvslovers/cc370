         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_cmp'
* Program text area
         DS    0F
* X-func *@@64CMP prologue
@@64CMP  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64CMP code
         L     5,0(11)
         L     4,4(11)
         LTR   5,5
         BE    @@L2
         LTR   4,4
         BE    @@L2
         DS    0H if (a->u64 > b->u64) return __64_LARGER;
         L     3,0(5)
         L     15,0(4)
         CLR   3,15
         BH    @@L4
         BNE   @@L3
         L     2,4(5)
         CL    2,4(4)
         BNH   @@L3
@@L4     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
         B     @@L1
@@L3     EQU   *
         DS    0H if (a->u64 < b->u64) return __64_SMALLER;
         L     12,0(,10)
         CLR   15,3
         BH    @@L6
         BNE   @@L2
         L     2,4(4)
         CL    2,4(5)
         BNH   @@L2
@@L6     EQU   *
         L     12,0(,10)
         L     15,=F'-1'
         B     @@L1
@@L2     EQU   *
         DS    0H return __64_EQUAL;
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64CMP epilogue
         PDPEPIL
* Function *@@64CMP literal pool
         DS    0F
         LTORG
* Function *@@64CMP page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
