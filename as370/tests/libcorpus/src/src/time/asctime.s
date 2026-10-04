         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'Sun'
         DC    C'Mon'
         DC    C'Tue'
         DC    C'Wed'
         DC    C'Thu'
         DC    C'Fri'
         DC    C'Sat'
@V2      EQU   *
         DC    C'Jan'
         DC    C'Feb'
         DC    C'Mar'
         DC    C'Apr'
         DC    C'May'
         DC    C'Jun'
         DC    C'Jul'
         DC    C'Aug'
         DC    C'Sep'
         DC    C'Oct'
         DC    C'Nov'
         DC    C'Dec'
@@LC0    EQU   *
         DC    C'%.3s %.3s%3d %.2d:%.2d:%.2d %d'
         DC    X'15'
         DC    X'0'
         DS    0F
* X-func asctime prologue
ASCTIME  PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function asctime code
         L     3,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    4,15
         A     4,=F'24'
         LTR   15,15
         BNE   @@L3
         L     4,=A(@V3)
@@L3     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC0)
         L     2,24(3)
         SLL   2,1
         A     2,24(3)
         A     2,=A(@V1)
         ST    2,96(13)
         L     2,16(3)
         SLL   2,1
         A     2,16(3)
         A     2,=A(@V2)
         ST    2,100(13)
         MVC   104(4,13),12(3)
         MVC   108(4,13),8(3)
         MVC   112(4,13),4(3)
         MVC   116(4,13),0(3)
         L     2,20(3)
         A     2,=F'1900'
         ST    2,120(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LR    15,4
* Function asctime epilogue
         PDPEPIL
* Function asctime literal pool
         DS    0F
         LTORG
* Function asctime page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
@V3      EQU   *
         DS    XL28
         END
