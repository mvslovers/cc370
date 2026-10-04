         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'racf_get_acee'
* Program text area
         DS    0F
* X-func *RACGACEE prologue
RACGACEE PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *RACGACEE code
         SLR   2,2
         L     2,548(2)
         L     2,108(2)
         A     2,=F'200'
         L     15,0(2)
* Function *RACGACEE epilogue
         PDPEPIL
* Function *RACGACEE literal pool
         DS    0F
         LTORG
* Function *RACGACEE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
