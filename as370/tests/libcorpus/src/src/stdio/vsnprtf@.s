         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'vsnprintf_'
* Program text area
         DS    0F
* X-func *VSNPRTF@ prologue
VSNPRTF@ PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *VSNPRTF@ code
         L     2,=V(@@PRTFX)
         L     2,0(2)
         MVC   88(4,13),0(2)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         MVC   104(4,13),12(11)
         L     2,44(2)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
* Function *VSNPRTF@ epilogue
         PDPEPIL
* Function *VSNPRTF@ literal pool
         DS    0F
         LTORG
* Function *VSNPRTF@ page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
