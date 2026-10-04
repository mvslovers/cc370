         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_from_u64'
* Program text area
         DS    0F
* X-func *@@64FU64 prologue
@@64FU64 PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64FU64 code
         L     15,0(11)
         LTR   15,15
         BE    @@L1
         MVC   0(8,15),4(11)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64FU64 epilogue
         PDPEPIL
* Function *@@64FU64 literal pool
         DS    0F
         LTORG
* Function *@@64FU64 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
