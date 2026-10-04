         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'closesocket'
* Program text area
         DS    0F
* X-func *@@75CLOS prologue
@@75CLOS PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75CLOS code
         L     2,0(11)
         LA    3,96(,13)
         XC    0(64,3),0(3)     clear __75 parameter list
         MVC   124(4,13),=F'12'
         ST    2,128(13)
         LA    3,96(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SODEL)
         BALR  14,15
         SLR   15,15
* Function *@@75CLOS epilogue
         PDPEPIL
* Function *@@75CLOS literal pool
         DS    0F
         LTORG
* Function *@@75CLOS page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
