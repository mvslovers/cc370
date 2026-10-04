         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_cmp_u32'
* Program text area
         DS    0F
* X-func *@@64CU32 prologue
@@64CU32 PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64CU32 code
         LA    2,96(,13)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         MVC   88(4,13),0(11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
* Function *@@64CU32 epilogue
         PDPEPIL
* Function *@@64CU32 literal pool
         DS    0F
         LTORG
* Function *@@64CU32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
