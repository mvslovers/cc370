         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osbdcb prologue
OSBDCB   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osbdcb code
         L     3,0(11)
         L     8,4(11)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'104'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L3
         MVC   0(PROTOLEN,15),PROTODCB
         LTR   3,3
         BE    @@L4
         CLI   2(3),122
         BNE   @@L5
         A     3,=F'3'
@@L5     EQU   *
         L     12,0(,10)
         SLR   6,6
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L4
         LR    4,3
         LR    5,7
         A     5,=F'40'
@@L9     EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L4
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L9
@@L4     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L3
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'40'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         ST    15,100(7)
         ST    15,36(7)
         SLR   6,6
         LR    5,15
@@L16    EQU   *
         L     2,0(8)
         LR    4,2
         SLL   4,24
         L     3,4(8)
         N     3,=F'16777215'
         OR    4,3
         ST    4,0(5)
         N     2,=F'128'
         LTR   2,2
         BNE   @@L13
         A     6,=F'1'
         A     5,=F'4'
         A     8,=F'8'
         LA    2,9(0,0)
         CR    6,2
         BNH   @@L16
@@L13    EQU   *
         L     12,0(,10)
         LA    2,10(0,0)
         CLR   6,2
         BNE   @@L17
         LA    6,9(0,0)
@@L17    EQU   *
         L     12,0(,10)
         LR    3,6
         SLL   3,2
         L     2,0(3,15)
         O     2,=F'-2147483648'
         ST    2,0(3,15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function osbdcb epilogue
         PDPEPIL
* Function osbdcb literal pool
         DS    0F
         LTORG
* Function osbdcb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
PROTODCB DCB DSORG=PS,MACRF=R
PROTOLEN EQU *-PROTODCB
         END
