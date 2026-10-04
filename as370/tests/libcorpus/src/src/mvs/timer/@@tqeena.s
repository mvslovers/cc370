         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tqe_enable'
* Program text area
         DS    0F
* X-func *@@TQEENA prologue
@@TQEENA PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TQEENA code
         L     8,0(11)
         LA    7,2(0,0)
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    4,15
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    6,15
         A     4,=F'24'
         ST    4,88(13)
         A     4,=F'-24'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   5,5
@@L12    EQU   *
         CLR   5,15
         BNL   @@L3
         L     3,24(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L4
         L     2,40(3)
         CLR   2,8
         BNE   @@L4
         NI    8(3),223
         L     2,24(3)
         LTR   2,2
         BE    @@L7
         MVC   88(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@TMSECS)
         BALR  14,15
         L     2,24(3)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         LTR   2,2
         BNL   @@L8
         AD    2,=D'4.294967296E+9'
@@L8     EQU   *
         L     12,0(,10)
         DD    2,=D'1.0E+2'
         ADR   2,0
         STD   2,16(3)
         A     4,=F'20'
         ST    4,88(13)
         A     4,=F'-20'
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ECBPST)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         SLR   7,7
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         B     @@L12
@@L3     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNE   @@L10
         ST    4,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L10    EQU   *
         L     12,0(,10)
         LR    15,7
* Function *@@TQEENA epilogue
         PDPEPIL
* Function *@@TQEENA literal pool
         DS    0F
         LTORG
* Function *@@TQEENA page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
