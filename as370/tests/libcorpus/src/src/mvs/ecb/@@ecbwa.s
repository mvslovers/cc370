         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ecb_waitarray'
* Program text area
         DS    0F
* X-func *@@ECBWA prologue
@@ECBWA  PDPPRLG CINDEX=0,FRAME=1120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ECBWA code
         SLR   7,7
         L     2,0(11)
         LTR   2,2
         BE    @@L3
         ST    11,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,7
         LR    3,7
         CLR   7,15
         BNL   @@L3
         LA    5,96(,13)
         L     4,0(11)
@@L9     EQU   *
         L     2,0(4)
         LTR   2,2
         BE    @@L6
         ST    2,0(5)
         A     3,=F'1'
         A     5,=F'4'
         LA    2,255(0,0)
         CLR   3,2
         BH    @@L5
@@L6     EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     4,=F'4'
         CLR   6,15
         BL    @@L9
@@L5     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L3
         SLL   3,2
         LA    2,96(,13)
         AR    3,2
         A     3,=F'-4'
         OC    0(4,3),=F'-2147483648'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ECBWL)
         BALR  14,15
         LR    7,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function *@@ECBWA epilogue
         PDPEPIL
* Function *@@ECBWA literal pool
         DS    0F
         LTORG
* Function *@@ECBWA page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
