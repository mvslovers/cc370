         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'getaddrbyname'
* Program text area
         DS    0F
* X-func *@@75GABN prologue
@@75GABN PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75GABN code
         L     4,0(11)
         SLR   3,3
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         ST    15,100(13)
         ST    4,116(13)
         MVC   124(4,13),=F'4'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     3,112(13)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@75GABN epilogue
         PDPEPIL
* Function *@@75GABN literal pool
         DS    0F
         LTORG
* Function *@@75GABN page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
