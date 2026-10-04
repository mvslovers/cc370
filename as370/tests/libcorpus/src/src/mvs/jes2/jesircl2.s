         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesircl2 prologue
JESIRCL2 PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesircl2 code
         L     3,0(11)
         L     5,4(11)
         SLR   4,4
         ST    4,96(13)
         LTR   5,5
         BE    @@L2
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,5           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,4            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L2     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L5
         L     2,136(3)
         A     3,=F'104'
         ENDREQ RPL=(3)
         ST  15,96(13)

         A     3,=F'-104'
         LTR   5,5
         BE    @@L6
         MVC   0(8,5),164(3)
@@L6     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(VSCLOSE)
         BALR  14,15
         LTR   2,2
         BE    @@L5
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         L     15,96(13)
* Function jesircl2 epilogue
         PDPEPIL
* Function jesircl2 literal pool
         DS    0F
         LTORG
* Function jesircl2 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
