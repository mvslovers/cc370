         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'Sun'
         DC    X'0'
@@LC1    EQU   *
         DC    C'Mon'
         DC    X'0'
@@LC2    EQU   *
         DC    C'Tue'
         DC    X'0'
@@LC3    EQU   *
         DC    C'Wed'
         DC    X'0'
@@LC4    EQU   *
         DC    C'Thu'
         DC    X'0'
@@LC5    EQU   *
         DC    C'Fri'
         DC    X'0'
@@LC6    EQU   *
         DC    C'Sat'
         DC    X'0'
* Program data area
         DS    0F
@V1      EQU   *
         DC    A(@@LC0)
         DC    A(@@LC1)
         DC    A(@@LC2)
         DC    A(@@LC3)
         DC    A(@@LC4)
         DC    A(@@LC5)
         DC    A(@@LC6)
* Program text area
@@LC7    EQU   *
         DC    C'Sunday'
         DC    X'0'
@@LC8    EQU   *
         DC    C'Monday'
         DC    X'0'
@@LC9    EQU   *
         DC    C'Tuesday'
         DC    X'0'
@@LC10   EQU   *
         DC    C'Wednesday'
         DC    X'0'
@@LC11   EQU   *
         DC    C'Thursday'
         DC    X'0'
@@LC12   EQU   *
         DC    C'Friday'
         DC    X'0'
@@LC13   EQU   *
         DC    C'Saturday'
         DC    X'0'
* Program data area
         DS    0F
@V2      EQU   *
         DC    A(@@LC7)
         DC    A(@@LC8)
         DC    A(@@LC9)
         DC    A(@@LC10)
         DC    A(@@LC11)
         DC    A(@@LC12)
         DC    A(@@LC13)
* Program text area
@@LC14   EQU   *
         DC    C'Jan'
         DC    X'0'
@@LC15   EQU   *
         DC    C'Feb'
         DC    X'0'
@@LC16   EQU   *
         DC    C'Mar'
         DC    X'0'
@@LC17   EQU   *
         DC    C'Apr'
         DC    X'0'
@@LC18   EQU   *
         DC    C'May'
         DC    X'0'
@@LC19   EQU   *
         DC    C'Jun'
         DC    X'0'
@@LC20   EQU   *
         DC    C'Jul'
         DC    X'0'
@@LC21   EQU   *
         DC    C'Aug'
         DC    X'0'
@@LC22   EQU   *
         DC    C'Sep'
         DC    X'0'
@@LC23   EQU   *
         DC    C'Oct'
         DC    X'0'
@@LC24   EQU   *
         DC    C'Nov'
         DC    X'0'
@@LC25   EQU   *
         DC    C'Dec'
         DC    X'0'
* Program data area
         DS    0F
@V3      EQU   *
         DC    A(@@LC14)
         DC    A(@@LC15)
         DC    A(@@LC16)
         DC    A(@@LC17)
         DC    A(@@LC18)
         DC    A(@@LC19)
         DC    A(@@LC20)
         DC    A(@@LC21)
         DC    A(@@LC22)
         DC    A(@@LC23)
         DC    A(@@LC24)
         DC    A(@@LC25)
* Program text area
@@LC26   EQU   *
         DC    C'January'
         DC    X'0'
@@LC27   EQU   *
         DC    C'February'
         DC    X'0'
@@LC28   EQU   *
         DC    C'March'
         DC    X'0'
@@LC29   EQU   *
         DC    C'April'
         DC    X'0'
@@LC30   EQU   *
         DC    C'June'
         DC    X'0'
@@LC31   EQU   *
         DC    C'July'
         DC    X'0'
@@LC32   EQU   *
         DC    C'August'
         DC    X'0'
@@LC33   EQU   *
         DC    C'September'
         DC    X'0'
@@LC34   EQU   *
         DC    C'October'
         DC    X'0'
@@LC35   EQU   *
         DC    C'November'
         DC    X'0'
@@LC36   EQU   *
         DC    C'December'
         DC    X'0'
* Program data area
         DS    0F
@V4      EQU   *
         DC    A(@@LC26)
         DC    A(@@LC27)
         DC    A(@@LC28)
         DC    A(@@LC29)
         DC    A(@@LC18)
         DC    A(@@LC30)
         DC    A(@@LC31)
         DC    A(@@LC32)
         DC    A(@@LC33)
         DC    A(@@LC34)
         DC    A(@@LC35)
         DC    A(@@LC36)
* Program text area
@@LC37   EQU   *
         DC    X'0'
* Program data area
         DS    0F
@V5      EQU   *
         DC    A(@@LC37)
         DS    XL4
* Program text area
@@LC38   EQU   *
         DC    C'%'
         DC    X'0'
@@LC39   EQU   *
         DC    C'%0 %0 %2 %2:%2:%2 %4'
         DC    X'0'
@@LC40   EQU   *
         DC    C'%2'
         DC    X'0'
@@LC41   EQU   *
         DC    C'%3'
         DC    X'0'
@@LC42   EQU   *
         DC    C'PM'
         DC    X'0'
@@LC43   EQU   *
         DC    C'AM'
         DC    X'0'
@@LC44   EQU   *
         DC    C'%1'
         DC    X'0'
@@LC45   EQU   *
         DC    C'%3s %3s %2 %4'
         DC    X'0'
@@LC46   EQU   *
         DC    C'%2:%2:%2'
         DC    X'0'
@@LC47   EQU   *
         DC    C'%4'
         DC    X'0'
         DS    0F
* X-func strftime prologue
STRFTIME PDPPRLG CINDEX=0,FRAME=224,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strftime code
         SLR   2,2
         SLR   3,3
         ST    2,168(13)
         ST    3,4+168(13)
         ST    2,176(13)
         ST    3,4+176(13)
         ST    2,184(13)
         ST    3,4+184(13)
         ST    2,192(13)
         ST    3,4+192(13)
         ST    2,200(13)
         ST    3,4+200(13)
         ST    2,208(13)
         ST    3,4+208(13)
         LR    8,2
         LR    9,3
         L     6,8(11)
         L     4,12(11)
         L     7,0(11)
         LR    3,7
         A     3,4(11)
         BCTR  3,0
         ST    3,160(13)
@@L64    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         L     14,=A(@@L52)
         BER   14
         IC    2,0(6)
         A     6,=F'1'
         CLM   2,1,=XL1'6C'
         L     14,=A(@@L4)
         BNER  14
         LA    5,128(,13)
         SLR   2,2
         IC    2,0(6)
         A     6,=F'1'
         LA    15,168(0,0)
         CR    2,15
         BE    @@L30
         BH    @@L37
         LA    3,132(0,0)
         CR    2,3
         BE    @@L12
         BH    @@L38
         LA    15,129(0,0)
         CR    2,15
         BE    @@L7
         BH    @@L39
         LA    3,108(0,0)
         CLR   2,3
         BE    @@L6
         B     @@L35
@@L39    EQU   *
         L     12,0(,10)
         LA    15,130(0,0)
         CLR   2,15
         BE    @@L9
         LA    3,131(0,0)
         CLR   2,3
         BE    @@L11
         B     @@L35
@@L38    EQU   *
         L     12,0(,10)
         LA    15,151(0,0)
         CR    2,15
         BE    @@L19
         BH    @@L40
         LA    3,145(0,0)
         CLR   2,3
         BE    @@L16
         LA    15,148(0,0)
         CLR   2,15
         BE    @@L17
         B     @@L35
@@L40    EQU   *
         L     12,0(,10)
         LA    3,166(0,0)
         CLR   2,3
         BE    @@L27
         LA    15,167(0,0)
         CLR   2,15
         BE    @@L28
         B     @@L35
@@L37    EQU   *
         L     12,0(,10)
         LA    3,226(0,0)
         CR    2,3
         BE    @@L22
         BH    @@L41
         LA    15,200(0,0)
         CR    2,15
         BE    @@L13
         BH    @@L42
         LA    3,193(0,0)
         CLR   2,3
         BE    @@L8
         LA    15,194(0,0)
         CLR   2,15
         BE    @@L10
         B     @@L35
@@L42    EQU   *
         L     12,0(,10)
         LA    3,201(0,0)
         CLR   2,3
         BE    @@L14
         LA    15,212(0,0)
         CLR   2,15
         BE    @@L18
         B     @@L35
@@L41    EQU   *
         L     12,0(,10)
         LA    3,231(0,0)
         CR    2,3
         BE    @@L29
         BH    @@L43
         LA    15,228(0,0)
         CLR   2,15
         BE    @@L23
         LA    3,230(0,0)
         CLR   2,3
         BE    @@L25
         B     @@L35
@@L43    EQU   *
         L     12,0(,10)
         LA    15,232(0,0)
         CLR   2,15
         BE    @@L31
         LA    3,233(0,0)
         CLR   2,3
         BE    @@L32
         B     @@L35
@@L6     EQU   *
         L     12,0(,10)
         L     5,=A(@@LC38)
         B     @@L5
@@L7     EQU   *
         L     12,0(,10)
         L     3,24(4)
         SLL   3,2
         L     2,=A(@V1)
         B     @@L58
@@L8     EQU   *
         L     12,0(,10)
         L     3,24(4)
         SLL   3,2
         L     2,=A(@V2)
         B     @@L58
@@L9     EQU   *
         L     12,0(,10)
         L     3,16(4)
         SLL   3,2
         L     2,=A(@V3)
         B     @@L58
@@L10    EQU   *
         L     12,0(,10)
         L     3,16(4)
         SLL   3,2
         L     2,=A(@V4)
@@L58    EQU   *
         L     12,0(,10)
         L     5,0(3,2)
         B     @@L5
@@L11    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC39)
         L     3,24(4)
         SLL   3,2
         L     2,=A(@V1)
         L     2,0(3,2)
         ST    2,96(13)
         L     3,16(4)
         SLL   3,2
         L     2,=A(@V3)
         L     2,0(3,2)
         ST    2,100(13)
         MVC   104(4,13),12(4)
         MVC   108(4,13),8(4)
         MVC   112(4,13),4(4)
         MVC   116(4,13),0(4)
         L     2,20(4)
         A     2,=F'1900'
         ST    2,120(13)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         B     @@L5
@@L12    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         MVC   96(4,13),12(4)
         B     @@L56
@@L13    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         MVC   96(4,13),8(4)
         B     @@L56
@@L14    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         L     15,8(4)
         ST    15,168(13)
         L     2,168(13)
         L     3,4+168(13)
         SRDA  2,32
         LA    15,12(0,0)
         DR    2,15
         ST    2,168(13)
         ST    3,4+168(13)
         L     2,168(13)
         LTR   2,2
         BNE   @@L60
         LR    2,15
         B     @@L60
@@L16    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC41)
         L     2,28(4)
         B     @@L62
@@L17    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         L     2,16(4)
@@L62    EQU   *
         L     12,0(,10)
         A     2,=F'1'
         B     @@L60
@@L18    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         MVC   96(4,13),4(4)
         B     @@L56
@@L19    EQU   *
         L     12,0(,10)
         L     2,8(4)
         L     5,=A(@@LC42)
         LA    3,11(0,0)
         CR    2,3
         BH    @@L5
         L     5,=A(@@LC43)
         B     @@L5
@@L22    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         MVC   96(4,13),0(4)
         B     @@L56
@@L23    EQU   *
         L     12,0(,10)
         L     15,28(4)
         ST    15,176(13)
         L     2,176(13)
         L     3,4+176(13)
         SRDA  2,32
         LA    15,7(0,0)
         DR    2,15
         ST    2,176(13)
         ST    3,4+176(13)
         ST    3,216(13)
         L     2,28(4)
         ST    2,184(13)
         L     2,184(13)
         L     3,4+184(13)
         SRDA  2,32
         DR    2,15
         ST    2,184(13)
         ST    3,4+184(13)
         L     2,24(4)
         L     3,184(13)
         B     @@L63
@@L25    EQU   *
         L     12,0(,10)
         L     2,28(4)
         ST    2,192(13)
         L     2,192(13)
         L     3,4+192(13)
         SRDA  2,32
         LA    15,7(0,0)
         DR    2,15
         ST    2,192(13)
         ST    3,4+192(13)
         ST    3,216(13)
         L     2,28(4)
         ST    2,200(13)
         L     2,200(13)
         L     3,4+200(13)
         SRDA  2,32
         DR    2,15
         ST    2,200(13)
         ST    3,4+200(13)
         L     2,24(4)
         A     2,=F'6'
         ST    2,208(13)
         L     2,208(13)
         L     3,4+208(13)
         SRDA  2,32
         DR    2,15
         ST    2,208(13)
         ST    3,4+208(13)
         L     3,200(13)
@@L63    EQU   *
         L     12,0(,10)
         CR    2,3
         BNL   @@L26
         L     15,216(13)
         A     15,=F'1'
         ST    15,216(13)
@@L26    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         MVC   96(4,13),216(13)
         B     @@L56
@@L27    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC44)
         MVC   96(4,13),24(4)
         B     @@L56
@@L28    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC45)
         L     3,24(4)
         SLL   3,2
         L     2,=A(@V1)
         L     2,0(3,2)
         ST    2,96(13)
         L     3,16(4)
         SLL   3,2
         L     2,=A(@V3)
         L     2,0(3,2)
         ST    2,100(13)
         MVC   104(4,13),12(4)
         L     2,20(4)
         A     2,=F'1900'
         ST    2,108(13)
         B     @@L57
@@L29    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC46)
         MVC   96(4,13),8(4)
         MVC   100(4,13),4(4)
         MVC   104(4,13),0(4)
@@L57    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         B     @@L5
@@L30    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC40)
         L     8,20(4)
         SRDA  8,32
         LA    2,100(0,0)
         DR    8,2
         ST    8,96(13)
         B     @@L56
@@L31    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC47)
         L     2,20(4)
         A     2,=F'1900'
@@L60    EQU   *
         L     12,0(,10)
         ST    2,96(13)
@@L56    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         B     @@L5
@@L32    EQU   *
         L     12,0(,10)
         L     2,32(4)
         L     3,=A(@V5)
         LTR   2,2
         BE    @@L33
         L     5,4(3)
         B     @@L5
@@L33    EQU   *
         L     12,0(,10)
         L     5,0(3)
         B     @@L5
@@L35    EQU   *
         L     12,0(,10)
         MVI   128(13),108
         L     2,=F'-1'
         IC    3,0(2,6)
         STC   3,129(13)
         MVI   130(13),0
         IC    2,0(2,6)
         CLM   2,1,=XL1'00'
         BNE   @@L5
         BCTR  6,0
@@L5     EQU   *
         L     12,0(,10)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L64
         CL    7,160(13)
         BE    @@L59
         IC    2,0(5)
         A     5,=F'1'
         STC   2,0(7)
         A     7,=F'1'
         B     @@L5
@@L4     EQU   *
         L     12,0(,10)
         CL    7,160(13)
         BNE   @@L49
@@L59    EQU   *
         L     12,0(,10)
         MVI   0(7),0
         SLR   15,15
         B     @@L1
@@L49    EQU   *
         L     12,0(,10)
         L     2,=F'-1'
         IC    2,0(2,6)
         STC   2,0(7)
         A     7,=F'1'
         B     @@L64
@@L52    EQU   *
         L     12,0(,10)
         MVI   0(7),0
         LR    15,7
         S     15,0(11)
@@L1     EQU   *
         L     12,0(,10)
* Function strftime epilogue
         PDPEPIL
* Function strftime literal pool
         DS    0F
         LTORG
* Function strftime page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
* Program data area
         DS    0F
@V6      EQU   *
         DC    F'1'
         DC    F'10'
         DC    F'100'
         DC    F'1000'
         DC    F'10000'
* Program text area
         DS    0F
* Function strfmt,F1 prologue
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
* Function strfmt code
         SLR   8,8
         SLR   9,9
         LR    6,8
         LR    7,9
         L     5,0(11)
         LA    2,8(,11)
         ST    2,88(13)
@@L87    EQU   *
         L     2,4(11)
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L80
         L     3,4(11)
         IC    2,0(3)
         A     3,=F'1'
         ST    3,4(11)
         CLM   2,1,=XL1'6C'
         BNE   @@L68
         SLR   15,15
         IC    15,0(3)
         A     15,=F'-240'
         A     3,=F'1'
         ST    3,4(11)
         L     2,88(13)
         A     2,=F'4'
         LTR   15,15
         BNE   @@L69
         ST    2,88(13)
         L     2,=F'-4'
         L     4,88(13)
         L     3,0(2,4)
@@L86    EQU   *
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L87
         IC    2,0(3)
         A     3,=F'1'
         STC   2,0(5)
         A     5,=F'1'
         B     @@L86
@@L69    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         L     2,=F'-4'
         L     3,88(13)
         L     4,0(2,3)
@@L76    EQU   *
         L     3,=A(@V6)
         LR    2,15
         SLL   2,2
         LR    8,4
         SRDA  8,32
         D     8,0(2,3)
         LR    2,8
         BCTR  15,0
         LR    4,2
         LR    2,15
         SLL   2,2
         LR    6,4
         SRDA  6,32
         D     6,0(2,3)
         LA    2,240(,7)
         STC   2,0(5)
         A     5,=F'1'
         LTR   15,15
         BNE   @@L76
         B     @@L87
@@L68    EQU   *
         L     12,0(,10)
         L     2,=F'-1'
         IC    3,0(2,3)
         STC   3,0(5)
         A     5,=F'1'
         B     @@L87
@@L80    EQU   *
         L     12,0(,10)
         MVI   0(5),0
* Function strfmt epilogue
         PDPEPIL
* Function strfmt literal pool
         DS    0F
         LTORG
* Function strfmt page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
