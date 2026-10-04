         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_rshift_word'
* Program text area
@V1      EQU   *
         DC    C'__64_rshift_word'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: *** shift corrected from %d to %d ***'
         DC    X'0'
         DS    0F
* X-func *@@64RSHW prologue
@@64RSHW PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64RSHW code
         L     6,0(11)
         L     2,4(11)
         LR    3,2
         LTR   6,6
         BE    @@L1
         LTR   2,2
         BL    @@L1
         LA    4,4(0,0)
         CR    2,4
         BNH   @@L4
         LR    3,4
@@L4     EQU   *
         L     12,0(,10)
         CLR   3,2
         BE    @@L5
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         ST    2,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         SLR   5,5
         CR    5,3
         BNL   @@L1
@@L13    EQU   *
         LA    4,3(0,0)
         LR    15,6
         A     15,=F'6'
@@L12    EQU   *
         LR    2,15
         A     2,=F'-2'
         MVC   0(2,15),0(2)
         BCTR  4,0
         LR    15,2
         LTR   4,4
         BH    @@L12
         MVC   0(2,6),=H'0'
         A     5,=F'1'
         CR    5,3
         BL    @@L13
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64RSHW epilogue
         PDPEPIL
* Function *@@64RSHW literal pool
         DS    0F
         LTORG
* Function *@@64RSHW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
