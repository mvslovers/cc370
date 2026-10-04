         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ikjct441 prologue
IKJCT441 PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ikjct441 code
         MVC   168(4,13),=F'0'
         L     2,4(11)
         LR    15,2
         LTR   2,2
         BE    @@L3
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         ST    15,172(13)
         SLR   3,3
         ST    3,176(13)
         MVC   180(4,13),=F'-1'
         L     2,16(3)
         L     2,156(2)
         L     15,40(2)
         ST    11,128(13)
         LA    9,168(,13)
         ST    9,156(13)
         LA    8,4(,11)
         ST    8,132(13)
         LA    7,172(,13)
         ST    7,136(13)
         LA    6,8(,11)
         ST    6,140(13)
         LA    5,12(,11)
         ST    5,144(13)
         LA    4,176(,13)
         ST    4,148(13)
         LA    2,180(,13)
         ST    2,152(13)
         ST    3,160(13)
         ST    11,88(13)
         ST    8,92(13)
         ST    7,96(13)
         ST    6,100(13)
         ST    5,104(13)
         ST    4,108(13)
         ST    2,112(13)
         ST    9,116(13)
         ST    3,120(13)
         LA    1,88(,13)
         LA    15,0(15)
         BALR  14,15
         L     15,168(13)
* Function ikjct441 epilogue
         PDPEPIL
* Function ikjct441 literal pool
         DS    0F
         LTORG
* Function ikjct441 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
