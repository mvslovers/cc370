         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'record'
         DC    X'0'
@@LC1    EQU   *
         DC    C'bsam'
         DC    X'0'
@@LC2    EQU   *
         DC    C'rlse'
         DC    X'0'
         DS    0F
* X-func __fpmode prologue
@@FPMODE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpmode code
         L     5,0(11)
         L     6,4(11)
         MVC   96(4,13),=F'1'
         LR    4,5
         A     4,=F'106'
         SLR   2,2
         LA    3,85(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,3           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,2            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LR    8,2
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L26
         LR    7,4
@@L29    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     9,=V(@@TOLOW)
         L     3,0(9)
         AR    2,2
         LH    2,0(2,3)
         STC   2,0(7)
         N     2,=XL4'000000FF'
         LA    3,129(0,0)
         CR    2,3
         BE    @@L7
         BH    @@L27
         LA    3,78(0,0)
         CLR   2,3
         BE    @@L16
         LA    3,107(0,0)
         CLR   2,3
         BE    @@L18
         B     @@L5
@@L27    EQU   *
         L     12,0(,10)
         LA    3,153(0,0)
         CR    2,3
         BE    @@L11
         BH    @@L28
         LA    3,130(0,0)
         CLR   2,3
         BE    @@L10
         B     @@L5
@@L28    EQU   *
         L     12,0(,10)
         LA    3,166(0,0)
         CLR   2,3
         BE    @@L14
         B     @@L5
@@L7     EQU   *
         L     12,0(,10)
         LH    3,40(5)
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BNE   @@L9
         O     3,=F'6144'
         B     @@L39
@@L10    EQU   *
         L     12,0(,10)
         OC    40(2,5),=H'1024'
         B     @@L5
@@L11    EQU   *
         L     12,0(,10)
         LH    4,40(5)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BNE   @@L9
         N     3,=F'2048'
         LTR   3,3
         BNE   @@L9
         O     4,=F'8192'
         STH   4,40(5)
         B     @@L5
@@L14    EQU   *
         L     12,0(,10)
         LH    3,40(5)
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BNE   @@L9
         O     3,=F'4096'
         B     @@L39
@@L16    EQU   *
         L     12,0(,10)
         LH    3,40(5)
         LR    2,3
         N     2,=F'12288'
         LTR   2,2
         BE    @@L9
         O     3,=F'12288'
@@L39    EQU   *
         L     12,0(,10)
         STH   3,40(5)
         B     @@L5
@@L18    EQU   *
         L     12,0(,10)
         LR    15,8
         LA    2,84(0,0)
         CLR   8,2
         BH    @@L20
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L20
         LR    4,8
         AR    4,5
         A     4,=F'106'
@@L22    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,0(9)
         AR    2,2
         A     6,=F'1'
         IC    2,1(2,3)
         STC   2,0(4)
         A     15,=F'1'
         A     4,=F'1'
         LA    3,84(0,0)
         CLR   15,3
         BH    @@L20
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BNE   @@L22
@@L20    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L23
         OC    40(2,5),=H'512'
@@L23    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L24
         OC    40(2,5),=H'256'
@@L24    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L26
         OC    40(2,5),=H'64'
         B     @@L26
@@L5     EQU   *
         L     12,0(,10)
         A     8,=F'1'
         A     7,=F'1'
         A     6,=F'1'
         LA    2,84(0,0)
         CLR   8,2
         BH    @@L26
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BNE   @@L29
@@L26    EQU   *
         L     12,0(,10)
         LH    4,40(5)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'12288'
         LTR   2,2
         BE    @@L9
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BE    @@L31
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BE    @@L31
         LR    2,3
         N     2,=F'512'
         LTR   2,2
         BNE   @@L9
         N     3,=F'2048'
         LTR   3,3
         BE    @@L33
         O     4,=F'32'
         STH   4,40(5)
@@L33    EQU   *
         L     12,0(,10)
         CLI   106(5),166
         BE    @@L31
         OC    40(2,5),=H'8'
@@L31    EQU   *
         L     12,0(,10)
         LH    4,40(5)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BE    @@L35
         N     3,=F'8192'
         LTR   3,3
         BE    @@L36
         CLI   106(5),153
         BE    @@L35
@@L36    EQU   *
         L     12,0(,10)
         O     4,=F'16'
         STH   4,40(5)
@@L35    EQU   *
         L     12,0(,10)
         MVC   96(4,13),=F'0'
@@L9     EQU   *
         L     12,0(,10)
         L     15,96(13)
* Function __fpmode epilogue
         PDPEPIL
* Function __fpmode literal pool
         DS    0F
         LTORG
* Function __fpmode page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
