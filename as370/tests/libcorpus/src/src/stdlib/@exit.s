         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func _Exit prologue
@EXIT    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function _Exit code
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L2
         L     2,16(15)
         LTR   2,2
         BE    @@L3
         A     3,=F'16'
         ST    3,88(13)
         A     3,=F'-16'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         L     2,20(3)
         LTR   2,2
         BE    @@L2
         A     3,=F'20'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@EXIT)
         BALR  14,15
* Function _Exit epilogue
         PDPEPIL
* Function _Exit literal pool
         DS    0F
         LTORG
* Function _Exit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
