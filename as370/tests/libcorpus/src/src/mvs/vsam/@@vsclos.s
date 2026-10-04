         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsclos prologue
@@VSCLOS PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsclos code
         L     3,0(11)
         MVC   96(8,13),=XL8'0000000000000000'
         LTR   3,3
         BE    @@L2
         IC    2,17(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L3
         A     3,=F'24'
         LA    2,96(,13)
         MVC   0($CLSLEN,2),CLSMODEL
         CLOSE ((3)),MF=(E,(2))
         A     3,=F'-24'
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function __vsclos epilogue
         PDPEPIL
* Function __vsclos literal pool
         DS    0F
         LTORG
* Function __vsclos page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
CLSMODEL CLOSE (*-*),MF=L
$CLSLEN  EQU   *-CLSMODEL
         END
