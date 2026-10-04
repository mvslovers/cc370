         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'.'
         DC    X'0'
@@LC1    EQU   *
         DC    X'0'
* Program data area
         DS    0F
@V1      EQU   *
         DC    A(@@LC0)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    A(@@LC1)
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
* Program text area
@@LC2    EQU   *
         DC    C'C'
         DC    X'0'
         DS    0F
* X-func setlocale prologue
SETLOCAL PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function setlocale code
         L     3,4(11)
         L     4,=A(@@LC2)
         LR    15,4
         LTR   3,3
         BE    @@L1
         CLC   0(2,3),0(4)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L5
         SLR   2,2
         IC    2,0(3)
         SLR   15,15
         LTR   2,2
         BNE   @@L1
@@L5     EQU   *
         L     12,0(,10)
         LR    15,4
@@L1     EQU   *
         L     12,0(,10)
* Function setlocale epilogue
         PDPEPIL
* Function setlocale literal pool
         DS    0F
         LTORG
* Function setlocale page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func localeconv prologue
LOCALECO PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function localeconv code
         L     15,=A(@V1)
* Function localeconv epilogue
         PDPEPIL
* Function localeconv literal pool
         DS    0F
         LTORG
* Function localeconv page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
