         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mktime prologue
MKTIME   PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mktime code
         L     4,0(11)
         L     3,20(4)
         LR    2,3
         A     2,=F'-70'
         LA    5,135(0,0)
         CLR   2,5
         BNH   @@L2
         MVC   104(4,13),=F'-1'
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         A     3,=F'1900'
         ST    3,88(13)
         L     2,16(4)
         A     2,=F'1'
         ST    2,92(13)
         MVC   96(4,13),12(4)
         LA    1,88(,13)
         L     15,=V(@@YMDTS)
         BALR  14,15
         A     15,=F'-719163'
         LR    2,15
         SLL   2,1
         AR    2,15
         SLL   2,3
         A     2,8(4)
         LR    3,2
         SLL   3,4
         SR    3,2
         SLL   3,2
         A     3,4(4)
         LR    2,3
         SLL   2,4
         SR    2,3
         SLL   2,2
         A     2,0(4)
         ST    2,104(13)
@@L3     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(GMTIME)
         BALR  14,15
         MVC   0(36,4),0(15)
         L     15,104(13)
* Function mktime epilogue
         PDPEPIL
* Function mktime literal pool
         DS    0F
         LTORG
* Function mktime page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
