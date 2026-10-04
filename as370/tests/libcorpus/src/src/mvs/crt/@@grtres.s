         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBGRT '
         DC    X'0'
         DS    0F
* X-func __grtres prologue
@@GRTRES PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __grtres code
         L     6,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    5,15
         LTR   2,2
         BE    @@L8
         L     4,280(2)
         LTR   4,4
         BE    @@L8
         L     2,=A(@@LC0)
         CLC   0(8,4),0(2)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L8
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LR    6,3
         LTR   5,5
         BE    @@L8
         L     2,16(5)
         CLR   2,4
         BNE   @@L8
         ST    3,16(5)
@@L8     EQU   *
         L     12,0(,10)
         LR    15,6
* Function __grtres epilogue
         PDPEPIL
* Function __grtres literal pool
         DS    0F
         LTORG
* Function __grtres page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
