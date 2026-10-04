         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'clib_find_cde'
* Program text area
@@LC0    EQU   *
         DC    C'        '
         DC    X'0'
         DS    0F
* X-func *@@FNDCDE prologue
@@FNDCDE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@FNDCDE code
         L     3,0(11)
         SLR   2,2
         L     2,540(2)
         L     2,124(2)
         L     15,44(2)
         L     2,=A(@@LC0)
         MVC   88(9,13),0(2)
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L3
         LA    4,88(,13)
         LR    5,3
         A     5,=F'7'
@@L5     EQU   *
         MVC   0(1,4),0(3)
         A     4,=F'1'
         A     3,=F'1'
         CR    3,5
         BH    @@L3
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L5
@@L3     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L12
         CLC   8(8,15),88(13)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L1
         L     15,0(15)
         B     @@L3
@@L12    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@FNDCDE epilogue
         PDPEPIL
* Function *@@FNDCDE literal pool
         DS    0F
         LTORG
* Function *@@FNDCDE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
