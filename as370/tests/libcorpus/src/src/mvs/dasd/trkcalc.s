         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func trkcalc prologue
TRKCALC  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function trkcalc code
         L     5,0(11)
         L     7,4(11)
         L     6,8(11)
         MVC   104(4,13),=F'0'
         MVC   108(4,13),=F'0'
         LA    8,88(,13)
         LA    9,12(0,0)
         SLR   2,2
         LR    3,2
         MVCL  8,2
         N     5,=F'15'
         LA    4,88(,13)
         LA    3,104(,13)
         LA    2,108(,13)
         
         TRKCALC FUNCTN=TRKCAP,REGSAVE=YES,                            X
               TYPE=(5),R=1,K=(7),DD=(6),MF=(E,(4))
         ST    15,0(3)
         ST    0,0(2)
         L     2,104(13)
         LTR   2,2
         BE    @@L3
         MVC   108(4,13),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         L     15,108(13)
* Function trkcalc epilogue
         PDPEPIL
* Function trkcalc literal pool
         DS    0F
         LTORG
* Function trkcalc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
