         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func qsort prologue
QSORT    PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function qsort code
         SLR   2,2
         SLR   3,3
         ST    2,112(13)
         ST    3,4+112(13)
         ST    2,120(13)
         ST    3,4+120(13)
         ST    2,128(13)
         ST    3,4+128(13)
         ST    2,136(13)
         ST    3,4+136(13)
         ST    2,144(13)
         ST    3,4+144(13)
         ST    2,160(13)
         ST    3,4+160(13)
         L     6,8(11)
         L     7,0(11)
         L     4,4(11)
         LA    3,1(0,0)
         CLR   4,3
         BNH   @@L25
@@L23    EQU   *
         MVC   104(4,13),=F'0'
         L     5,4(11)
         BCTR  5,0
         LR    8,5
         SRL   8,1
         ST    5,164(13)
         L     2,160(13)
         L     3,4+160(13)
         MR    2,6
         ST    2,160(13)
         ST    3,4+160(13)
         AR    3,7
         ST    3,152(13)
         LR    9,7
         MVC   168(4,13),=F'0'
@@L4     EQU   *
         L     4,168(13)
         AR    4,7
         B     @@L6
@@L8     EQU   *
         L     3,104(13)
         A     3,=F'1'
         ST    3,104(13)
         L     2,168(13)
         AR    2,6
         ST    2,168(13)
         AR    9,6
         AR    4,6
@@L6     EQU   *
         L     12,0(,10)
         ST    6,116(13)
         L     2,112(13)
         L     3,4+112(13)
         MR    2,8
         ST    2,112(13)
         ST    3,4+112(13)
         L     2,116(13)
         AR    2,7
         ST    2,88(13)
         ST    4,92(13)
         L     3,12(11)
         LA    1,88(,13)
         LA    15,0(3)
         BALR  14,15
         LTR   15,15
         BH    @@L8
         ST    5,148(13)
         L     2,144(13)
         L     3,4+144(13)
         MR    2,6
         ST    2,144(13)
         ST    3,4+144(13)
         AR    3,7
         ST    3,176(13)
         B     @@L9
@@L11    EQU   *
         BCTR  5,0
         LCR   2,6
         L     3,152(13)
         AR    3,2
         ST    3,152(13)
         A     2,176(13)
         ST    2,176(13)
@@L9     EQU   *
         L     12,0(,10)
         ST    6,124(13)
         L     2,120(13)
         L     3,4+120(13)
         MR    2,8
         ST    2,120(13)
         ST    3,4+120(13)
         L     2,124(13)
         AR    2,7
         ST    2,88(13)
         MVC   92(4,13),176(13)
         L     3,12(11)
         LA    1,88(,13)
         LA    15,0(3)
         BALR  14,15
         LTR   15,15
         BL    @@L11
         L     4,104(13)
         CLR   4,5
         BNL   @@L5
         SLR   15,15
@@L28    EQU   *
         CLR   15,6
         BNL   @@L27
         LR    2,9
         AR    2,15
         IC    4,0(2)
         L     3,152(13)
         AR    3,15
         MVC   0(1,2),0(3)
         STC   4,0(3)
         A     15,=F'1'
         B     @@L28
@@L27    EQU   *
         L     12,0(,10)
         CL    8,104(13)
         BNE   @@L17
         LR    8,5
         B     @@L18
@@L17    EQU   *
         L     12,0(,10)
         CLR   8,5
         BNE   @@L18
         L     8,104(13)
@@L18    EQU   *
         L     12,0(,10)
         L     2,104(13)
         A     2,=F'1'
         ST    2,104(13)
         L     3,168(13)
         AR    3,6
         ST    3,168(13)
         AR    9,6
         BCTR  5,0
         L     4,152(13)
         SR    4,6
         ST    4,152(13)
         B     @@L4
@@L5     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         L     3,4(11)
         SR    3,5
         CLR   5,3
         BNL   @@L20
         ST    7,88(13)
         ST    5,92(13)
         ST    6,96(13)
         MVC   100(4,13),12(11)
         LA    1,88(,13)
         L     15,=A(QSORT)
         BALR  14,15
         ST    6,132(13)
         L     8,128(13)
         L     9,4+128(13)
         MR    8,5
         ST    8,128(13)
         ST    9,4+128(13)
         AR    7,9
         ST    3,4(11)
         B     @@L2
@@L20    EQU   *
         L     12,0(,10)
         ST    6,140(13)
         L     8,136(13)
         L     9,4+136(13)
         MR    8,5
         ST    8,136(13)
         ST    9,4+136(13)
         L     2,140(13)
         AR    2,7
         ST    2,88(13)
         ST    3,92(13)
         ST    6,96(13)
         MVC   100(4,13),12(11)
         LA    1,88(,13)
         L     15,=A(QSORT)
         BALR  14,15
         ST    5,4(11)
@@L2     EQU   *
         L     12,0(,10)
         L     2,4(11)
         LA    9,1(0,0)
         CLR   2,9
         BH    @@L23
@@L25    EQU   *
         L     12,0(,10)
* Function qsort epilogue
         PDPEPIL
* Function qsort literal pool
         DS    0F
         LTORG
* Function qsort page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
