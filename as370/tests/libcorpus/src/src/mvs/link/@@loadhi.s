         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__loadhi'
* Program text area
@V1      EQU   *
         DC    C'__loadhi'
         DC    X'0'
@@LC0    EQU   *
         DC    C'        '
         DC    X'0'
         DS    XL3
@@LC1    EQU   *
         DC    C'%s unable to LOAD "%s" into private storage'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s CDE not found for "%s"'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s unable to allocate storage for %u bytes from '
         DC    C'subpool 241'
         DC    X'0'
@@LC4    EQU   *
         DC    C'DD:STEPLIB('
         DC    X'0'
@@LC5    EQU   *
         DC    C')'
         DC    X'0'
@@LC6    EQU   *
         DC    C'rb'
         DC    X'0'
@@LC7    EQU   *
         DC    C'%s unable to open "%s" for reading'
         DC    X'0'
@@LC8    EQU   *
         DC    C'%s relocation of "%s" failed, module not loaded'
         DC    X'0'
         DS    0F
* X-func *@@LOADHI prologue
@@LOADHI PDPPRLG CINDEX=0,FRAME=192,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@LOADHI code
         SLR   7,7
         ST    7,176(13)
         ST    7,180(13)
         L     2,=A(@@LC0)
         MVC   104(9,13),0(2)
         LA    4,113(,13)
         LA    5,3(0,0)
         LR    2,7
         LR    3,7
         MVCL  4,2
         LA    2,120(,13)
         LR    4,2
         LA    5,56(0,0)
         LR    2,7
         LR    3,7
         MVCL  4,2
         L     3,0(11)
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L3
         LR    4,3
         LA    5,104(,13)
         LR    6,3
         A     6,=F'7'
@@L5     EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     5,=F'1'
         A     4,=F'1'
         CR    4,6
         BH    @@L3
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L5
@@L3     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@STEPLB)
         BALR  14,15
         ST    15,88(13)
         LA    8,104(,13)
         ST    8,92(13)
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LOAD)
         BALR  14,15
         LR    9,15
         LTR   15,15
         BNE   @@L6
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),=A(@V1)
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L19
@@L6     EQU   *
         L     12,0(,10)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@FNDCDE)
         BALR  14,15
         LTR   15,15
         BNE   @@L8
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@V1)
         ST    8,96(13)
         B     @@L21
@@L8     EQU   *
         L     12,0(,10)
         L     2,20(15)
         L     3,8(2)
         N     3,=F'16777215'
         ST    3,180(13)
         L     6,12(2)
         LR    2,9
         SR    2,6
         ST    2,184(13)
         ST    3,88(13)
         MVC   92(4,13),=F'241'
         LA    1,88(,13)
         L     15,=V(GETMAIN)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BNE   @@L9
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@V1)
         MVC   96(4,13),180(13)
@@L21    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L12
@@L9     EQU   *
         L     12,0(,10)
         LR    4,15
         L     5,180(13)
         LR    2,6
         LR    3,5
         MVCL  4,2
         L     2,=A(@@LC4)
         MVC   120(12,13),0(2)
         LA    3,120(,13)
         ST    3,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L10
         MVC   88(4,13),=A(@@LC7)
         MVC   92(4,13),=A(@V1)
         ST    3,96(13)
         B     @@L21
@@L10    EQU   *
         L     12,0(,10)
         ST    15,88(13)
         ST    6,92(13)
         ST    7,96(13)
         MVC   100(4,13),180(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LTR   15,15
         BE    @@L11
         MVC   88(4,13),=A(@@LC8)
         MVC   92(4,13),=A(@V1)
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L7
@@L11    EQU   *
         L     12,0(,10)
         L     3,184(13)
         AR    3,7
         ST    3,176(13)
@@L7     EQU   *
         L     12,0(,10)
         LTR   2,2
         BE    @@L12
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L13
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@DELETE)
         BALR  14,15
@@L13    EQU   *
         L     12,0(,10)
         L     2,176(13)
         LTR   2,2
         BE    @@L14
         L     3,4(11)
         LTR   3,3
         BE    @@L15
         ST    7,0(3)
@@L15    EQU   *
         L     12,0(,10)
         L     2,8(11)
         LTR   2,2
         BE    @@L16
         MVC   0(4,2),176(13)
@@L16    EQU   *
         L     12,0(,10)
         L     3,12(11)
         LTR   3,3
         BE    @@L17
         MVC   0(4,3),180(13)
@@L17    EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L1
@@L14    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L19
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(FREEMAIN)
         BALR  14,15
@@L19    EQU   *
         L     12,0(,10)
         LA    15,4(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@LOADHI epilogue
         PDPEPIL
* Function *@@LOADHI literal pool
         DS    0F
         LTORG
* Function *@@LOADHI page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'relocate_load'
@V2      EQU   *
         DC    C'relocate_load'
         DC    X'0'
@@LC9    EQU   *
         DC    C'%s %d RLD item(s) address outside the %u byte mo'
         DC    C'dule and were not relocated'
         DC    X'0'
         DS    0F
* Function relocate_load,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=120,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function relocate_load code
         L     6,0(11)
         L     9,8(11)
         L     8,12(11)
         SLR   4,4
         ST    4,116(13)
         ST    4,112(13)
         LR    7,4
         LR    5,4
@@L34    EQU   *
         MVC   88(4,13),8(6)
         LA    2,112(,13)
         ST    2,92(13)
         LA    2,116(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AREAD)
         BALR  14,15
         LTR   15,15
         BNE   @@L30
         LTR   7,7
         BE    @@L26
         LR    7,15
         B     @@L34
@@L26    EQU   *
         L     12,0(,10)
         L     3,112(13)
         SLR   15,15
         IC    15,0(3)
         LR    2,15
         N     2,=F'1'
         LTR   2,2
         BE    @@L27
         LA    7,1(0,0)
@@L27    EQU   *
         L     12,0(,10)
         N     15,=F'2'
         LTR   15,15
         BE    @@L34
         ST    3,88(13)
         MVC   92(4,13),116(13)
         MVC   96(4,13),4(11)
         ST    9,100(13)
         ST    8,104(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         AR    5,15
         B     @@L34
@@L30    EQU   *
         L     12,0(,10)
         OC    40(2,6),=H'1'
         LTR   5,5
         BE    @@L29
         MVC   88(4,13),=A(@@LC9)
         MVC   92(4,13),=A(@V2)
         ST    5,96(13)
         ST    8,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LA    4,4(0,0)
@@L29    EQU   *
         L     12,0(,10)
         LR    15,4
* Function relocate_load epilogue
         PDPEPIL
* Function relocate_load literal pool
         DS    0F
         LTORG
* Function relocate_load page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'process_rldr'
         DS    0F
* Function process_rldr,F7 prologue
@@F7     PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function process_rldr code
         L     4,0(11)
         L     3,4(11)
         SLR   15,15
         ST    15,92(13)
         LH    2,6(4)
         N     2,=XL4'0000FFFF'
         LA    5,16(0,0)
         CLR   3,5
         BNH   @@L36
         A     3,=F'-16'
         CLR   2,3
         BNH   @@L36
         LR    2,3
@@L36    EQU   *
         L     12,0(,10)
         LR    8,4
         A     8,=F'16'
         LR    9,8
         AR    9,2
         A     4,=F'20'
         CLR   4,9
         BH    @@L38
@@L55    EQU   *
         L     2,92(13)
         LTR   2,2
         BNE   @@L39
         LR    2,8
         A     2,=F'8'
         CLR   2,9
         BH    @@L38
         A     8,=F'4'
@@L39    EQU   *
         L     12,0(,10)
         IC    2,0(8)
         SLR   5,5
         IC    5,1(8)
         SLL   5,16
         SLR   3,3
         IC    3,2(8)
         SLL   3,8
         OR    5,3
         SLR   3,3
         IC    3,3(8)
         OR    5,3
         A     8,=F'4'
         LR    3,2
         N     3,=XL4'000000FF'
         LR    4,3
         N     4,=F'1'
         ST    4,92(13)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BL    @@L37
         N     3,=F'12'
         LA    2,4(0,0)
         CLR   3,2
         BNE   @@L42
         LA    3,2(0,0)
         B     @@L43
@@L42    EQU   *
         L     12,0(,10)
         LA    4,8(0,0)
         CLR   3,4
         BNE   @@L44
         LA    3,3(0,0)
         B     @@L43
@@L44    EQU   *
         L     12,0(,10)
         LA    2,12(0,0)
         CLR   3,2
         BNE   @@L37
         LA    3,4(0,0)
@@L43    EQU   *
         L     12,0(,10)
         LR    2,5
         AR    2,3
         CL    2,16(11)
         BNH   @@L48
         A     15,=F'1'
         B     @@L37
@@L48    EQU   *
         L     12,0(,10)
         L     7,8(11)
         AR    7,5
         SLR   4,4
         LR    6,4
         CLR   4,3
         BNL   @@L58
@@L52    EQU   *
         SLL   4,8
         SLR   2,2
         IC    2,0(6,7)
         OR    4,2
         A     6,=F'1'
         CLR   6,3
         BL    @@L52
@@L58    EQU   *
         L     12,0(,10)
         LR    2,4
         S     2,8(11)
         A     2,12(11)
         ST    2,88(13)
         LR    2,13
         SR    2,3
         L     6,12(11)
         AR    6,5
         LR    7,3
         LR    4,2
         A     4,=F'92'
         LR    5,3
         MVCL  6,4
@@L37    EQU   *
         L     12,0(,10)
         LR    2,8
         A     2,=F'4'
         CLR   2,9
         BNH   @@L55
@@L38    EQU   *
         L     12,0(,10)
* Function process_rldr epilogue
         PDPEPIL
* Function process_rldr literal pool
         DS    0F
         LTORG
* Function process_rldr page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         END
