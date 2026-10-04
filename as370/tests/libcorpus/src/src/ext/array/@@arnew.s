         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arraynew'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARNEW prologue
@@ARNEW  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARNEW code
         L     3,0(11)
         LTR   3,3
         BNE   @@L2
         LA    3,20(0,0)
@@L2     EQU   *
         L     12,0(,10)
         A     3,=F'3'
         ST    3,88(13)
         A     3,=F'-3'
         MVC   92(4,13),=F'4'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         L     2,=A(@@LC0)
         MVC   0(4,15),0(2)
         ST    3,4(15)
         MVC   8(4,15),=F'0'
         A     15,=F'12'
@@L4     EQU   *
         L     12,0(,10)
* Function *@@ARNEW epilogue
         PDPEPIL
* Function *@@ARNEW literal pool
         DS    0F
         LTORG
* Function *@@ARNEW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
