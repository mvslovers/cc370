         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'listen'
* Program text area
         DS    0F
* X-func *@@75LIST prologue
@@75LIST PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75LIST code
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         MVC   124(4,13),=F'8'
         MVC   128(4,13),0(11)
         MVC   132(4,13),4(11)
         LA    3,96(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     2,112(13)
         LTR   2,2
         BE    @@L3
         MVC   100(4,13),=F'0'
         MVC   124(4,13),=F'2'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@75LIST epilogue
         PDPEPIL
* Function *@@75LIST literal pool
         DS    0F
         LTORG
* Function *@@75LIST page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
