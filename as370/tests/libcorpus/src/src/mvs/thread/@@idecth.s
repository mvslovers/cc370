         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'clib_identify_cthread'
* Program text area
         DS    0F
* X-func *@@IDECTH prologue
@@IDECTH PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@IDECTH code
         SLR   3,3
         ST    3,88(13)
         LA    2,88(,13)
         L     1,=V(CTHREAD)    A(thread driver routine)
         LA    0,=CL8'CTHREAD'
         IDENTIFY EPLOC=(0),ENTRY=(1)
         ST    15,0(,2)

         
*

         LR    15,3
* Function *@@IDECTH epilogue
         PDPEPIL
* Function *@@IDECTH literal pool
         DS    0F
         LTORG
* Function *@@IDECTH page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
