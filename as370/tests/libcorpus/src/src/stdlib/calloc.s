         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func calloc prologue
CALLOC   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function calloc code
         SLR   2,2
         SLR   3,3
         LR    4,2
         LR    5,3
         L     6,0(11)
         L     15,4(11)
         LTR   15,15
         BE    @@L2
         L     2,=F'-8'
         SLR   3,3
         CLR   15,2
         BH    @@L5
         LTR   15,15
         BL    @@L4
         LA    7,1(0,0)
         CLR   15,7
         BE    @@L3
         SRDL  2,32
         DR    2,15
         B     @@L5
@@L3     EQU   *
         L     12,0(,10)
         LR    3,2
         B     @@L5
@@L4     EQU   *
         L     12,0(,10)
         LA    3,1(0,0)
@@L5     EQU   *
         L     12,0(,10)
         CLR   6,3
         BNH   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'12'
         SLR   15,15
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LR    5,6
         MR    4,15
         LR    3,5
         A     3,=F'7'
         N     3,=F'-8'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(MALLOC)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L6
         
* Clear allocated memory
         LR    14,2   => ptr
         LR    15,3   == total size
         SLR   0,0
         LR    1,0
         MVCL  14,0

@@L6     EQU   *
         L     12,0(,10)
         LR    15,2
@@L1     EQU   *
         L     12,0(,10)
* Function calloc epilogue
         PDPEPIL
* Function calloc literal pool
         DS    0F
         LTORG
* Function calloc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
