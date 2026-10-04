         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osbopen prologue
OSBOPEN  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osbopen code
         L     3,0(11)
         L     2,8(11)
         MVC   104(4,13),=F'-1'
         LTR   3,3
         BE    @@L3
         LTR   2,2
         BE    @@L4
         SLR   4,4
         IC    4,0(2)
         LR    2,4
         LA    4,166(0,0)
         CR    2,4
         BE    @@L13
         BH    @@L18
         LA    4,150(0,0)
         CR    2,4
         BE    @@L13
         BH    @@L19
         LA    4,137(0,0)
         CLR   2,4
         BE    @@L9
         LA    4,147(0,0)
         B     @@L25
@@L19    EQU   *
         L     12,0(,10)
         LA    4,153(0,0)
         CLR   2,4
         BE    @@L9
         LA    4,164(0,0)
         CLR   2,4
         BE    @@L17
         B     @@L4
@@L18    EQU   *
         L     12,0(,10)
         LA    4,214(0,0)
         CR    2,4
         BE    @@L13
         BH    @@L20
         LA    4,201(0,0)
         CLR   2,4
         BE    @@L9
         LA    4,211(0,0)
@@L25    EQU   *
         L     12,0(,10)
         CLR   2,4
         BE    @@L15
         B     @@L4
@@L20    EQU   *
         L     12,0(,10)
         LA    4,228(0,0)
         CR    2,4
         BE    @@L17
         BH    @@L21
         LA    4,217(0,0)
         CLR   2,4
         BE    @@L9
         B     @@L4
@@L21    EQU   *
         L     12,0(,10)
         LA    4,230(0,0)
         CLR   2,4
         BE    @@L13
         B     @@L4
@@L9     EQU   *
         L     12,0(,10)
         MVI   50(3),32
         MVI   51(3),0
         B     @@L4
@@L13    EQU   *
         L     12,0(,10)
         MVI   50(3),0
         B     @@L24
@@L15    EQU   *
         L     12,0(,10)
         MVI   50(3),0
         MVI   51(3),40
         B     @@L4
@@L17    EQU   *
         L     12,0(,10)
         MVI   50(3),32
@@L24    EQU   *
         L     12,0(,10)
         MVI   51(3),32
@@L4     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@F1)
         ST    3,92(13)
         MVC   96(4,13),4(11)
         LA    2,104(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         ST    15,104(13)
         LTR   15,15
         BNE   @@L3
         IC    2,48(3)
         N     2,=F'16'
         LTR   2,2
         BNE   @@L3
         MVC   104(4,13),=F'8'
@@L3     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function osbopen epilogue
         PDPEPIL
* Function osbopen literal pool
         DS    0F
         LTORG
* Function osbopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'opendcb'
         DS    0F
* Function opendcb,F1 prologue
@@F1     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function opendcb code
         L     3,0(11)
         L     4,8(11)
         LR    2,3
         O     2,=F'-2147483648'
         ST    2,88(13)
         IC    2,51(3)
         N     2,=F'32'
         LTR   2,2
         BE    @@L27
         IC    2,50(3)
         N     2,=F'32'
         LTR   2,2
         BE    @@L28
         O     3,=F'-2080374784'
         B     @@L32
@@L28    EQU   *
         L     12,0(,10)
         O     3,=F'-1895825408'
@@L32    EQU   *
         L     12,0(,10)
         ST    3,88(13)
@@L27    EQU   *
         L     12,0(,10)
         LA    3,88(,13)
         L     2,4(11)
         LTR   2,2
         BNE   @@L30
         LR    1,3
         SVC   19         OPEN
         ST    15,0(,4)
         B     @@L26
@@L30    EQU   *
         LR    1,3
         SVC   22         OPENJ
         ST    15,0(,4)
@@L26    EQU   *
         L     12,0(,10)
* Function opendcb epilogue
         PDPEPIL
* Function opendcb literal pool
         DS    0F
         LTORG
* Function opendcb page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         OPEN ((2),OUTPUT)
         END
