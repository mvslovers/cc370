         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func gets prologue
GETS     PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function gets code
         L     3,0(11)
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=F'2147483647'
         MVC   96(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FGETS)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L2
         ST    3,88(13)
         MVC   92(4,13),=F'21'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         MVI   0(15),0
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
* Function gets epilogue
         PDPEPIL
* Function gets literal pool
         DS    0F
         LTORG
* Function gets page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
