         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_divmod'
* Program text area
         DS    0F
* X-func *@@64DMOD prologue
@@64DMOD PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64DMOD code
         L     4,0(11)
         L     2,4(11)
         L     6,8(11)
         L     5,12(11)
         LTR   4,4
         BE    @@L1
         LTR   2,2
         BE    @@L1
         LTR   6,6
         BE    @@L1
         LTR   5,5
         BE    @@L1
         ST    4,88(13)
         ST    2,92(13)
         LA    3,104(,13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64DIV)
         BALR  14,15
         ST    3,88(13)
         ST    2,92(13)
         LA    2,112(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MUL)
         BALR  14,15
         ST    4,88(13)
         ST    2,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SUB)
         BALR  14,15
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64DMOD epilogue
         PDPEPIL
* Function *@@64DMOD literal pool
         DS    0F
         LTORG
* Function *@@64DMOD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
