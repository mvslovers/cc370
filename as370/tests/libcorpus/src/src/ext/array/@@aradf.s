         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arrayaddf'
* Program text area
         DS    0F
* X-func *@@ARADF prologue
@@ARADF  PDPPRLG CINDEX=0,FRAME=1128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARADF code
         L     5,0(11)
         L     4,=F'-1'
         LTR   5,5
         BE    @@L5
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),4(11)
         LA    2,8(,11)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(VSPRINTF)
         BALR  14,15
         MVC   88(4,13),=F'1'
         A     15,=F'1'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L5
         ST    15,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    5,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    4,15
@@L5     EQU   *
         L     12,0(,10)
         LR    15,4
* Function *@@ARADF epilogue
         PDPEPIL
* Function *@@ARADF literal pool
         DS    0F
         LTORG
* Function *@@ARADF page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
