         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_func_every'
* Program text area
         DS    0F
* X-func *@@TMRFUE prologue
@@TMRFUE PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMRFUE code
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    2,15
         SLR   4,4
         LR    15,4
         LTR   2,2
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@TMSTRT)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         MVC   104(4,13),=F'192'
         LA    1,88(,13)
         L     15,=V(@@TQNEW)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         L     4,40(15)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    5,15
         A     2,=F'24'
         ST    2,88(13)
         A     2,=F'-24'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   4,4
         B     @@L5
@@L4     EQU   *
         L     12,0(,10)
         A     2,=F'20'
         ST    2,88(13)
         A     2,=F'-20'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ECBPST)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         LTR   5,5
         BNE   @@L3
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
@@L1     EQU   *
         L     12,0(,10)
* Function *@@TMRFUE epilogue
         PDPEPIL
* Function *@@TMRFUE literal pool
         DS    0F
         LTORG
* Function *@@TMRFUE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
