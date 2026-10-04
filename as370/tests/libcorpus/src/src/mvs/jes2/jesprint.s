         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'Unable to allocate storage for %u byte buffer'
         DC    X'0'
         DS    0F
* X-func jesprint prologue
JESPRINT PDPPRLG CINDEX=0,FRAME=192,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesprint code
         L     3,0(11)
         L     6,4(11)
         L     4,20(11)
         MVC   176(4,13),=F'503'
         SLR   8,8
         LR    7,8
         LTR   4,4
         BNE   @@L2
         LA    4,112(,13)
@@L2     EQU   *
         L     12,0(,10)
         LA    2,20(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,7            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LA    2,32(0,0)
         LA    5,136(,13)
         
*** MEMSET ***
         LR    14,5           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,7            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         MVC   12(4,4),=F'1'
         MVC   168(4,13),12(11)
         MVC   172(4,13),16(11)
         LTR   3,3
         BE    @@L6
         LTR   6,6
         BE    @@L6
         L     15,8(11)
         LTR   15,15
         BE    @@L6
         L     2,8(3)
         LTR   2,2
         BE    @@L6
         A     2,=F'20'
         ST    2,184(13)
         LH    9,176(2)
         N     9,=XL4'0000FFFF'
         L     2,12(3)
         LTR   2,2
         BE    @@L6
         MVC   180(4,13),0(2)
         L     2,180(13)
         LTR   2,2
         BE    @@L6
         MVC   88(4,13),=F'1'
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BNE   @@L12
         MVC   88(4,13),=A(@@LC0)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   12(4,4),=F'9'
         B     @@L6
@@L45    EQU   *
         LR    8,3
         B     @@L14
@@L46    EQU   *
         MVC   12(4,4),=F'6'
         B     @@L34
@@L47    EQU   *
         MVC   12(4,4),=F'2'
         B     @@L34
@@L48    EQU   *
         MVC   12(4,4),=F'5'
         ST    2,8(4)
         B     @@L6
@@L12    EQU   *
         L     12,0(,10)
         A     6,=F'48'
         ST    6,88(13)
         A     6,=F'-48'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,8
         CLR   8,15
         BNL   @@L14
@@L18    EQU   *
         L     3,48(6)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L15
         LH    2,94(3)
         N     2,=XL4'0000FFFF'
         CL    2,8(11)
         BE    @@L45
@@L15    EQU   *
         L     12,0(,10)
         A     5,=F'1'
         CLR   5,15
         BL    @@L18
@@L14    EQU   *
         L     12,0(,10)
         MVC   176(4,13),=F'404'
         LTR   8,8
         BE    @@L6
         MVC   176(4,13),=F'0'
         L     2,84(8)
         LTR   2,2
         BE    @@L6
         MVC   12(4,4),176(13)
         L     5,84(8)
@@L49    EQU   *
         LTR   5,5
         BE    @@L6
         L     2,0(4)
         L     3,=F'65535'
         CLR   2,3
         BH    @@L46
         MVC   88(4,13),180(13)
         ST    5,92(13)
         ST    7,96(13)
         L     15,184(13)
         LH    2,176(15)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         BNE   @@L47
         L     2,72(6)
         CL    2,4(7)
         BE    @@L26
         L     2,0(4)
         LA    3,10(0,0)
         LTR   2,2
         BNE   @@L28
         LA    3,3(0,0)
@@L28    EQU   *
         L     12,0(,10)
         ST    3,12(4)
         B     @@L34
@@L26    EQU   *
         L     12,0(,10)
         LH    2,94(8)
         L     3,0(4)
         MVC   80(2,13),8(7)
         CLM   2,3,80(13)
         BE    @@L29
         LA    2,10(0,0)
         LTR   3,3
         BNE   @@L31
         LA    2,4(0,0)
@@L31    EQU   *
         L     12,0(,10)
         ST    2,12(4)
         B     @@L34
@@L29    EQU   *
         L     12,0(,10)
         A     3,=F'1'
         ST    3,0(4)
         ST    7,88(13)
         ST    9,92(13)
         LA    2,136(,13)
         ST    2,96(13)
         MVC   100(4,13),=A(@@F6)
         LA    3,168(,13)
         ST    3,104(13)
         LA    1,88(,13)
         L     15,=V(@@JESPRB)
         BALR  14,15
         L     2,156(13)
         LTR   15,15
         BNL   @@L32
         LA    15,3(0,0)
         CLR   2,15
         BNE   @@L33
         MVC   88(4,13),=A(@@LC0)
         L     2,140(13)
         A     2,=F'4'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   12(4,4),=F'9'
         B     @@L34
@@L33    EQU   *
         L     12,0(,10)
         MVC   12(4,4),=F'7'
         MVC   16(4,4),160(13)
@@L34    EQU   *
         L     12,0(,10)
         ST    5,8(4)
         B     @@L6
@@L32    EQU   *
         L     12,0(,10)
         LA    3,2(0,0)
         CLR   2,3
         BE    @@L36
         LA    15,4(0,0)
         CLR   2,15
         BNE   @@L35
@@L36    EQU   *
         L     12,0(,10)
         LA    3,11(0,0)
         LA    15,4(0,0)
         CLR   2,15
         BE    @@L38
         LA    3,8(0,0)
@@L38    EQU   *
         L     12,0(,10)
         ST    3,12(4)
         ST    5,8(4)
@@L35    EQU   *
         L     12,0(,10)
         L     2,0(7)
         CLR   2,5
         BE    @@L48
         LR    5,2
         B     @@L49
@@L6     EQU   *
         L     12,0(,10)
         MVC   4(4,4),152(13)
         L     2,136(13)
         LTR   2,2
         BE    @@L41
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L41    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L42
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L42    EQU   *
         L     12,0(,10)
         L     15,176(13)
* Function jesprint epilogue
         PDPEPIL
* Function jesprint literal pool
         DS    0F
         LTORG
* Function jesprint page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'esc_print'
         DS    0F
* Function esc_print,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function esc_print code
         L     3,0(11)
         L     2,4(11)
         L     4,8(11)
         SLR   15,15
         LTR   2,2
         BE    @@L52
         LA    5,1(0,0)
         CLR   2,5
         BNH   @@L54
         LR    15,3
         AR    15,2
         BCTR  15,0
@@L58    EQU   *
         CLI   0(15),64
         BNE   @@L54
         BCTR  2,0
         BCTR  15,0
         LA    5,1(0,0)
         CLR   2,5
         BH    @@L58
@@L54    EQU   *
         L     12,0(,10)
         LA    5,255(0,0)
         CLR   2,5
         BNH   @@L56
         LR    2,5
@@L56    EQU   *
         LR    1,3          => our print line
         LR    14,2         => length of line
         BCTR  14,0        decrement for execute
         EX    14,TRLINE     translate unsafe characters
         L     12,0(,10)
         ST    3,88(13)
         ST    2,92(13)
         MVC   96(4,13),4(4)
         L     2,0(4)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
@@L52    EQU   *
         L     12,0(,10)
* Function esc_print epilogue
         PDPEPIL
* Function esc_print literal pool
         DS    0F
         LTORG
* Function esc_print page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
TRLINE   TR    0(*-*,1),PRTXLATE   REMOVE UNPRINTABLES
         
PRTXLATE DC    64C' ',191AL1(*-PRTXLATE),C' '
         END
