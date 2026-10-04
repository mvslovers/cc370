         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_id'
* Program text area
         DS    0F
* X-func *@@TMRID prologue
@@TMRID  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMRID code
         SLR   4,4
         SLR   5,5
         LR    8,4
         LR    9,5
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    3,15
         SLR   6,6
         LR    15,6
         LTR   3,3
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    7,15
@@L18    EQU   *
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         L     2,28(3)
         XR    2,15
         LR    15,2
         N     15,=F'16777215'
         ST    15,28(3)
         N     2,=F'3'
         LA    15,1(0,0)
         CLR   2,15
         BE    @@L7
         BL    @@L6
         LA    15,2(0,0)
         CLR   2,15
         BE    @@L8
         LA    15,3(0,0)
         CLR   2,15
         BE    @@L12
         B     @@L5
@@L6     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         L     6,28(3)
         SR    6,15
         B     @@L5
@@L7     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         L     6,28(3)
         XR    6,15
         B     @@L5
@@L8     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         A     15,=F'1'
         L     4,28(3)
         CLR   15,4
         BH    @@L11
         LTR   15,15
         BL    @@L10
         LA    2,1(0,0)
         CLR   15,2
         BE    @@L9
         SRDL  4,32
         DR    4,15
         B     @@L11
@@L9     EQU   *
         L     12,0(,10)
         SLR   4,4
         B     @@L11
@@L10    EQU   *
         L     12,0(,10)
         SR    4,15
@@L11    EQU   *
         L     12,0(,10)
         LR    6,4
         B     @@L5
@@L12    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         N     15,=XL4'000000FF'
         L     9,28(3)
         MR    8,15
         LR    6,9
@@L5     EQU   *
         L     12,0(,10)
         N     6,=F'16777215'
         LA    15,1000(0,0)
         CLR   6,15
         BNH   @@L18
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LTR   15,15
         BE    @@L18
         LTR   7,7
         BNE   @@L14
         ST    3,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         LR    15,6
@@L1     EQU   *
         L     12,0(,10)
* Function *@@TMRID epilogue
         PDPEPIL
* Function *@@TMRID literal pool
         DS    0F
         LTORG
* Function *@@TMRID page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'unique_id'
         DS    0F
* Function unique_id,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function unique_id code
         L     4,0(11)
         L     6,4(11)
         LA    7,1(0,0)
         A     4,=F'24'
         ST    4,88(13)
         A     4,=F'-24'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   5,5
@@L29    EQU   *
         CLR   5,15
         BNL   @@L28
         L     3,24(4)
         LR    2,5
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L22
         L     2,40(2)
         CLR   2,6
         BNE   @@L22
         SLR   7,7
         B     @@L26
@@L22    EQU   *
         L     12,0(,10)
         A     5,=F'1'
         B     @@L29
@@L28    EQU   *
         L     12,0(,10)
         ST    6,28(4)
@@L26    EQU   *
         L     12,0(,10)
         LR    15,7
* Function unique_id epilogue
         PDPEPIL
* Function unique_id literal pool
         DS    0F
         LTORG
* Function unique_id page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
