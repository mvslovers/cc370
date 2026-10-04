         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'31'
         DC    F'28'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'31'
         DC    F'29'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         DC    F'30'
         DC    F'31'
         
&FUNC    SETC 'days_in_month'
         DS    0F
* X-func *TM64DIM prologue
TM64DIM  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64DIM code
         L     2,0(11)
         SLL   2,1
         A     2,0(11)
         SLL   2,2
         A     2,4(11)
         SLL   2,2
         L     3,=A(@V1)
         L     15,0(2,3)
* Function *TM64DIM epilogue
         PDPEPIL
* Function *TM64DIM literal pool
         DS    0F
         LTORG
* Function *TM64DIM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
