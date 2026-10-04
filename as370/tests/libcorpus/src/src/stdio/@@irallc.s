         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'INTRDR'
         DC    X'0'
         DS    0F
* X-func __irallc prologue
@@IRALLC PDPPRLG CINDEX=0,FRAME=216,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __irallc code
         L     6,0(11)
         SLR   15,15
         ST    15,208(13)
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    2,208(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSYSO)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@TXPGM)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCLOS)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         LR    2,15
         BCTR  2,0
         L     4,208(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),1
         MVI   98(13),64
         MVC   104(4,13),208(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         L     2,208(13)
         L     2,0(2)
         MVC   43(8,6),6(2)
         OC    40(2,6),=H'-32768'
@@L3     EQU   *
         L     12,0(,10)
         L     2,208(13)
         LTR   2,2
         BE    @@L9
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __irallc epilogue
         PDPEPIL
* Function __irallc literal pool
         DS    0F
         LTORG
* Function __irallc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
