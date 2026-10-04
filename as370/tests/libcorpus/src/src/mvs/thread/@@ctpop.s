         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_pop'
* Program text area
         DS    0F
* X-func *@@CTPOP prologue
@@CTPOP  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTPOP code
         L     8,0(11)
         SLR   5,5
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         LR    7,5
         LR    6,5
         LTR   15,15
         BE    @@L3
         LR    4,15
         A     4,=F'332'
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L4
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         LR    7,15
         A     3,=F'336'
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         LR    6,15
@@L4     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LTR   7,7
         BE    @@L3
         LA    2,2(0,0)
         CLR   8,2
         BE    @@L9
         BH    @@L11
         LA    2,1(0,0)
         CLR   8,2
         BE    @@L8
         B     @@L3
@@L11    EQU   *
         L     12,0(,10)
         LA    2,3(0,0)
         CLR   8,2
         BE    @@L10
         B     @@L3
@@L8     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         LA    15,0(7)
         BALR  14,15
         B     @@L12
@@L9     EQU   *
         L     12,0(,10)
         ST    7,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         LR    5,15
         B     @@L3
@@L10    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ABRPT)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         LA    15,0(7)
         BALR  14,15
         LR    5,15
         MVC   88(4,13),=F'2'
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ABRPT)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function *@@CTPOP epilogue
         PDPEPIL
* Function *@@CTPOP literal pool
         DS    0F
         LTORG
* Function *@@CTPOP page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
