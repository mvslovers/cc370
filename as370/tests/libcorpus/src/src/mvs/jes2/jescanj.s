         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jescanj prologue
JESCANJ  PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jescanj code
         L     5,0(11)
         L     6,4(11)
         LA    7,104(,13)
         ST    7,88(13)
         LA    4,128(,13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(INITSSOB)
         BALR  14,15
         MVC   110(2,13),=H'2'
         SLR   3,3
         LA    2,40(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         MVC   128(2,13),=H'40'
         LTR   5,5
         BE    @@L3
         LA    2,132(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'8'
         ST    5,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L4
         LA    2,140(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'8'
         ST    6,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         L     2,8(11)
         LTR   2,2
         BE    @@L5
         MVI   130(13),64
@@L5     EQU   *
         L     12,0(,10)
         MVC   148(2,13),=H'16'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(IEFSSREQ)
         BALR  14,15
@@L6     EQU   *
         L     15,116(13)
* Function jescanj epilogue
         PDPEPIL
* Function jescanj literal pool
         DS    0F
         LTORG
* Function jescanj page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
