         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'r'
         DC    X'0'
         DS    0F
* X-func loadenv prologue
LOADENV  PDPPRLG CINDEX=0,FRAME=1136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function loadenv code
         LA    2,1(0,0)
         MVC   88(4,13),0(11)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         B     @@L23
@@L15    EQU   *
         ST    4,88(13)
         MVC   92(4,13),=F'21'
         LA    1,88(,13)
         L     15,=V(STRRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L6
         MVI   0(15),0
@@L6     EQU   *
         L     12,0(,10)
         IC    2,104(13)
         CLM   2,1,=XL1'5C'
         BE    @@L23
         CLM   2,1,=XL1'7B'
         BE    @@L23
         ST    4,88(13)
         LA    2,1128(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L22
         L     2,1128(13)
         AR    2,4
         A     2,=F'-8'
         MVI   0(2),0
         L     2,1128(13)
         A     2,=F'-8'
         ST    2,1128(13)
         B     @@L22
@@L21    EQU   *
         IC    2,104(13,2)
         SLL   2,24
         SRA   2,24
         C     2,=F'64'
         BNE   @@L11
         SLR   2,2
         STC   2,104(13,15)
@@L22    EQU   *
         L     12,0(,10)
         L     2,1128(13)
         BCTR  2,0
         ST    2,1128(13)
         LR    15,2
         LTR   2,2
         BH    @@L21
@@L11    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'126'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L23
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(PUTENV)
         BALR  14,15
@@L23    EQU   *
         L     12,0(,10)
         LA    4,104(,13)
         ST    4,88(13)
         MVC   92(4,13),=F'1024'
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(FGETS)
         BALR  14,15
         LTR   15,15
         BNE   @@L15
         LR    2,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L16
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
@@L16    EQU   *
         L     12,0(,10)
         LR    15,2
* Function loadenv epilogue
         PDPEPIL
* Function loadenv literal pool
         DS    0F
         LTORG
* Function loadenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'numbered'
         DS    0F
* Function numbered,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function numbered code
         L     3,0(11)
         SLR   4,4
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         L     2,4(11)
         ST    15,0(2)
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L26
         AR    15,3
         A     15,=F'-8'
@@L34    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L33
         IC    3,0(15)
         LA    2,16(,3)
         CLM   2,1,=XL1'09'
         BH    @@L26
         A     15,=F'1'
         B     @@L34
@@L33    EQU   *
         L     12,0(,10)
         LA    4,1(0,0)
@@L26    EQU   *
         L     12,0(,10)
         LR    15,4
* Function numbered epilogue
         PDPEPIL
* Function numbered literal pool
         DS    0F
         LTORG
* Function numbered page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
