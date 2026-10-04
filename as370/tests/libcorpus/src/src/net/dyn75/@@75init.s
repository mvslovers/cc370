         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '@@75init'
* Program text area
         DS    0F
* X-func __75init prologue
@@75INIT PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __75init code
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    4,15
         L     15,=F'-1'
         LTR   4,4
         BE    @@L1
         LR    3,4
         A     3,=F'28'
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         L     2,0(3)
         LTR   2,2
         BNE   @@L3
         MVC   88(4,13),=F'1024'
         LA    1,88(,13)
         L     15,=V(@@ARNEW)
         BALR  14,15
         ST    15,0(3)
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         MVC   124(4,13),=F'1'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         OI    10(4),128
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         L     15,156(13)
@@L1     EQU   *
         L     12,0(,10)
* Function __75init epilogue
         PDPEPIL
* Function __75init literal pool
         DS    0F
         LTORG
* Function __75init page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
