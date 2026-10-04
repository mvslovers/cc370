         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'snprintf_'
* Program text area
         DS    0F
* X-func *SNPRTF@ prologue
SNPRTF@  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *SNPRTF@ code
         L     2,=V(@@PRTFX)
         L     3,0(2)
         MVC   88(4,13),0(3)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         LA    2,12(,11)
         ST    2,104(13)
         L     2,44(3)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
* Function *SNPRTF@ epilogue
         PDPEPIL
* Function *SNPRTF@ literal pool
         DS    0F
         LTORG
* Function *SNPRTF@ page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
