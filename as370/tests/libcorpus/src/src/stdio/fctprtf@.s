         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'fctprintf_'
* Program text area
         DS    0F
* X-func *FCTPRTF@ prologue
FCTPRTF@ PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *FCTPRTF@ code
         MVC   112(4,13),0(11)
         LA    3,112(,13)
         MVC   4(4,3),4(11)
         L     2,=V(@@PRTFX)
         L     4,0(2)
         MVC   88(4,13),12(4)
         ST    3,92(13)
         MVC   96(4,13),=F'-1'
         MVC   100(4,13),8(11)
         LA    2,12(,11)
         ST    2,104(13)
         L     2,44(4)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
* Function *FCTPRTF@ epilogue
         PDPEPIL
* Function *FCTPRTF@ literal pool
         DS    0F
         LTORG
* Function *FCTPRTF@ page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
