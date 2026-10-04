         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    X'50'
         DC    X'50'
         DC    C'TMP%05u'
         DC    X'0'
         DS    0F
* X-func tmpnam prologue
TMPNAM   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tmpnam code
         L     4,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L7
         L     2,280(15)
         LTR   2,2
         BNE   @@L4
@@L7     EQU   *
         L     12,0(,10)
         LR    15,2
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         LR    3,2
         A     3,=F'12'
         A     15,=F'284'
         LTR   4,4
         BNE   @@L5
         LR    4,15
@@L5     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         L     2,0(3)
         L     5,=F'99998'
         CLR   2,5
         BNH   @@L6
         MVC   0(4,3),=F'0'
@@L6     EQU   *
         L     12,0(,10)
         L     2,0(3)
         A     2,=F'1'
         ST    2,0(3)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC0)
         MVC   96(4,13),0(3)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,4
@@L1     EQU   *
         L     12,0(,10)
* Function tmpnam epilogue
         PDPEPIL
* Function tmpnam literal pool
         DS    0F
         LTORG
* Function tmpnam page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
