         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'recv'
* Program text area
         DS    0F
* X-func *@@75RECV prologue
@@75RECV PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75RECV code
         L     7,0(11)
         L     6,4(11)
         L     5,8(11)
         SLR   3,3
         LTR   7,7
         BL    @@L3
         LTR   6,6
         BNE   @@L2
@@L3     EQU   *
         L     12,0(,10)
         L     3,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'1'
         B     @@L4
@@L2     EQU   *
         L     12,0(,10)
         LR    4,3
         CR    3,5
         BNL   @@L4
@@L11    EQU   *
         LR    3,6
         AR    3,4
         LR    15,5
         SR    15,4
         LA    2,256(0,0)
         CR    15,2
         BNH   @@L8
         LR    15,2
@@L8     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         ST    3,120(13)
         MVC   124(4,13),=F'11'
         ST    7,128(13)
         ST    15,132(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     3,112(13)
         L     2,=F'-2'
         CLR   3,2
         BNE   @@L9
         STIMER WAIT,BINTVL==F'8'   0.08 seconds
         SLR   3,3
         B     @@L7
@@L9     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNH   @@L6
@@L7     EQU   *
         L     12,0(,10)
         AR    4,3
         CR    4,5
         BL    @@L11
@@L6     EQU   *
         L     12,0(,10)
         L     2,=F'-1'
         CLR   3,2
         BNE   @@L12
         MVC   100(4,13),=F'0'
         MVC   124(4,13),=F'2'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
@@L12    EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L4
         LR    3,4
@@L4     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@75RECV epilogue
         PDPEPIL
* Function *@@75RECV literal pool
         DS    0F
         LTORG
* Function *@@75RECV page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
