         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __stow prologue
@@STOW   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __stow code
         L     3,0(11)
         L     2,4(11)
         L     15,8(11)
         L     4,=F'-1'
         LA    5,153(0,0)
         CR    15,5
         BE    @@L6
         BH    @@L11
         LA    5,131(0,0)
         CR    15,5
         BE    @@L10
         BH    @@L12
         LA    5,129(0,0)
         B     @@L14
@@L12    EQU   *
         L     12,0(,10)
         LA    5,132(0,0)
         CLR   15,5
         BE    @@L8
         B     @@L2
@@L11    EQU   *
         L     12,0(,10)
         LA    5,195(0,0)
         CR    15,5
         BE    @@L10
         BH    @@L13
         LA    5,193(0,0)
@@L14    EQU   *
         L     12,0(,10)
         CLR   15,5
         BE    @@L4
         B     @@L2
@@L13    EQU   *
         L     12,0(,10)
         LA    5,196(0,0)
         CLR   15,5
         BE    @@L8
         LA    5,217(0,0)
         CLR   15,5
         BE    @@L6
         B     @@L2
@@L4     EQU   *
         LR    R1,3
         LR    R0,2
         SVC   21
         LR    4,R15
         L     12,0(,10)
         B     @@L2
@@L6     EQU   *
         LR    R1,3
         LR    R0,2
         LCR   R1,R1
         SVC   21
         LR    4,R15
         L     12,0(,10)
         B     @@L2
@@L8     EQU   *
         LR    R1,3
         LR    R0,2
         LCR   R0,R0
         SVC   21
         LR    4,R15
         L     12,0(,10)
         B     @@L2
@@L10    EQU   *
         LR    R1,3
         LR    R0,2
         LCR   R1,R1
         LCR   R0,R0
         SVC   21
         LR    4,R15
@@L2     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __stow epilogue
         PDPEPIL
* Function __stow literal pool
         DS    0F
         LTORG
* Function __stow page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
