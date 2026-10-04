         COPY  PDPTOP
         CSECT
         DS    0F
@V1      EQU   *
         DS    XL4
* Program text area
         DS    0F
* X-func strtok prologue
STRTOK   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtok code
         L     2,0(11)
         L     5,4(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    4,15
         A     4,=F'276'
         LTR   15,15
         BNE   @@L3
         L     4,=A(@V1)
@@L3     EQU   *
         L     12,0(,10)
         LTR   2,2
         BE    @@L4
         ST    2,0(4)
@@L4     EQU   *
         L     12,0(,10)
         L     2,0(4)
         LR    15,2
         LTR   2,2
         BE    @@L1
         LR    3,2
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRSPN)
         BALR  14,15
         LR    2,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         CLR   15,2
         BH    @@L6
         MVC   0(4,4),=F'0'
         SLR   15,15
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         AR    3,2
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRCSPN)
         BALR  14,15
         LR    2,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         CLR   15,2
         BH    @@L7
         MVC   0(4,4),=F'0'
         B     @@L8
@@L7     EQU   *
         L     12,0(,10)
         SLR   5,5
         STC   5,0(2,3)
         AR    2,3
         A     2,=F'1'
         ST    2,0(4)
@@L8     EQU   *
         L     12,0(,10)
         LR    15,3
@@L1     EQU   *
         L     12,0(,10)
* Function strtok epilogue
         PDPEPIL
* Function strtok literal pool
         DS    0F
         LTORG
* Function strtok page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
