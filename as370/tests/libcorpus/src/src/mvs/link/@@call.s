         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__call'
* Program text area
         DS    0F
* X-func __call prologue
@@CALL   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __call code
         L     2,0(11)
         L     3,4(11)
         LR    15,2          => function to call 
         LR    1,3           => parameter list
         BALR  14,15         call function
         LR    2,15          save return code
         LR    15,2
* Function __call epilogue
         PDPEPIL
* Function __call literal pool
         DS    0F
         LTORG
* Function __call page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
