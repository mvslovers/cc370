         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'bind'
* Program text area
         DS    0F
* X-func *@@75BIND prologue
@@75BIND PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75BIND code
         L     5,0(11)
         L     4,4(11)
         L     6,8(11)
         LH    2,2(4)
         CLM   2,3,=H'0'
         BNE   @@L2
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(TIME)
         BALR  14,15
         L     2,168(13)
         N     2,=F'32767'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(SRAND)
         BALR  14,15
         SLR   3,3
@@L7     EQU   *
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         SLL   15,16
         SRA   15,16
         N     15,=F'32767'
         A     15,=F'10000'
         STH   15,2(4)
         ST    5,88(13)
         ST    4,92(13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@75BIND)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L9
         A     3,=F'1'
         LA    2,99(0,0)
         CR    3,2
         BNH   @@L7
         MVC   2(2,4),=H'0'
@@L2     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         LR    2,5
         SLL   2,16
         O     2,=F'6'
         ST    2,132(13)
         MVC   136(4,13),4(4)
         LH    2,0(4)
         SLL   2,16
         LH    3,2(4)
         N     3,=XL4'0000FFFF'
         OR    2,3
         N     2,=F'16777215'
         ST    2,140(13)
         LA    3,104(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     2,120(13)
         LTR   2,2
         BL    @@L8
         ST    5,88(13)
         ST    4,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@SOUPD)
         BALR  14,15
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'0'
         ST    5,136(13)
         MVC   132(4,13),=F'2'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),120(13)
@@L9     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@75BIND epilogue
         PDPEPIL
* Function *@@75BIND literal pool
         DS    0F
         LTORG
* Function *@@75BIND page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
