         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *CMTTGET prologue
CMTTGET  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *CMTTGET code
         SLR   4,4
         SLR   5,5
         L     7,0(11)
         MVC   96(4,13),=F'0'
         LTR   7,7
         BE    @@L3
         L     6,8(7)
         LTR   6,6
         BE    @@L3
         L     2,12(7)
         ST    2,96(13)
         LTR   2,2
         BNE   @@L3
         L     4,40(6)
         SRDL  4,32
         LA    2,80(0,0)
         DR    4,2
         LR    2,5
         LA    3,9(0,0)
         CLR   5,3
         BH    @@L6
         LA    2,10(0,0)
@@L6     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARNEW)
         BALR  14,15
         ST    15,96(13)
         L     3,4(6)
         B     @@L31
@@L25    EQU   *
         AR    2,3
         A     2,=F'10'
         CLR   2,4
         BH    @@L8
         LA    2,96(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LH    2,8(3)
         AR    3,2
         A     3,=F'10'
@@L31    EQU   *
         L     12,0(,10)
         CL    3,8(6)
         BL    @@L8
         L     4,12(6)
         CLR   3,4
         BNL   @@L8
         LH    2,8(3)
         CH    2,=H'0'
         BNL   @@L25
@@L8     EQU   *
         L     12,0(,10)
         L     3,32(6)
         B     @@L33
@@L27    EQU   *
         AR    2,3
         A     2,=F'10'
         CLR   2,4
         BH    @@L12
         LA    2,96(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LH    2,8(3)
         AR    3,2
         A     3,=F'10'
@@L33    EQU   *
         L     12,0(,10)
         CL    3,8(6)
         BL    @@L12
         L     4,12(6)
         CLR   3,4
         BNL   @@L12
         CL    3,4(6)
         BNL   @@L12
         LH    2,8(3)
         CH    2,=H'0'
         BNL   @@L27
@@L12    EQU   *
         L     12,0(,10)
         MVC   12(4,7),96(13)
         LA    8,96(,13)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LA    2,1(0,0)
         CLR   15,2
         BNH   @@L3
         
* inline reverse_mtentry_array start
         MVC   100(4,13),96(13)
         LA    2,100(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   6,6
         LR    7,15
         SRL   7,1
         CLR   6,7
         BNL   @@L24
         SLL   15,2
@@L19    EQU   *
         L     3,100(13)
         LR    4,6
         SLL   4,2
         L     5,0(4,3)
         LR    2,15
         AR    2,3
         A     2,=F'-4'
         L     2,0(2)
         ST    2,0(4,3)
         LR    2,15
         A     2,100(13)
         A     2,=F'-4'
         ST    5,0(2)
         A     6,=F'1'
         A     15,=F'-4'
         CLR   6,7
         BL    @@L19
@@L24    EQU   *
         
* inline reverse_mtentry_array end
         L     12,0(,10)
         ST    8,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         L     15,96(13)
* Function *CMTTGET epilogue
         PDPEPIL
* Function *CMTTGET literal pool
         DS    0F
         LTORG
* Function *CMTTGET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
