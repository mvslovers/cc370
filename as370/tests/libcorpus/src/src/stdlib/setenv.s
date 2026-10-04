         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func setenv prologue
SETENV   PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function setenv code
         L     8,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         ST    15,108(13)
         MVC   112(4,13),=F'0'
         L     15,=F'-1'
         L     2,108(13)
         LTR   2,2
         BE    @@L1
         A     2,=F'32'
         ST    2,120(13)
         ST    2,88(13)
         MVC   92(4,13),112(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
@@L29    EQU   *
         CLI   0(8),64
         BNE   @@L25
         A     8,=F'1'
         B     @@L29
@@L25    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L9
         LR    2,8
         AR    2,15
         BCTR  2,0
@@L30    EQU   *
         CLI   0(2),64
         BNE   @@L9
         BCTR  7,0
         BCTR  2,0
         LTR   7,7
         BNE   @@L30
@@L9     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L31
         L     3,4(11)
         LTR   3,3
         BE    @@L31
         ST    8,88(13)
         LA    2,104(,13)
         ST    2,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@FINDEN)
         BALR  14,15
         ST    15,116(13)
         LTR   15,15
         BNE   @@L14
         ST    8,88(13)
         ST    2,92(13)
         MVC   96(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@FINDEN)
         BALR  14,15
         ST    15,116(13)
@@L14    EQU   *
         L     12,0(,10)
         L     4,116(13)
         LTR   4,4
         BE    @@L15
         L     2,8(11)
         LTR   2,2
         BE    @@L13
@@L15    EQU   *
         L     12,0(,10)
         L     2,4(11)
         CLI   0(2),64
         BNE   @@L28
@@L18    EQU   *
         L     3,4(11)
         A     3,=F'1'
         ST    3,4(11)
         CLI   0(3),64
         BE    @@L18
@@L28    EQU   *
         L     12,0(,10)
         MVC   88(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    9,15
         LR    2,7
         AR    2,15
         A     2,=F'12'
         MVC   88(4,13),=F'1'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L19
@@L31    EQU   *
         L     12,0(,10)
         MVC   112(4,13),=F'1'
         B     @@L13
@@L19    EQU   *
         L     12,0(,10)
         LR    3,15
         A     3,=F'8'
         ST    3,0(15)
         LR    2,15
         AR    2,7
         A     2,=F'9'
         ST    2,4(15)
         LR    4,3
         LR    5,7
         LR    2,8
         LR    3,7
         MVCL  4,2
         L     4,4(15)
         LR    5,9
         L     2,4(11)
         LR    3,9
         MVCL  4,2
         L     2,104(13)
         LTR   2,2
         BL    @@L20
         L     4,108(13)
         L     3,32(4)
         SLL   2,2
         L     4,116(13)
         LTR   4,4
         BE    @@L21
         L     3,0(2,3)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,108(13)
         L     3,32(2)
         L     2,104(13)
         SLL   2,2
@@L21    EQU   *
         L     12,0(,10)
         ST    6,0(2,3)
         B     @@L13
@@L20    EQU   *
         L     12,0(,10)
         MVC   88(4,13),120(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         ST    15,112(13)
         LTR   15,15
         BE    @@L13
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L13    EQU   *
         L     12,0(,10)
         L     3,108(13)
         A     3,=F'32'
         ST    3,108(13)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         L     15,112(13)
@@L1     EQU   *
         L     12,0(,10)
* Function setenv epilogue
         PDPEPIL
* Function setenv literal pool
         DS    0F
         LTORG
* Function setenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
