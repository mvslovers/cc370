         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_lshift_word'
* Program text area
@V1      EQU   *
         DC    C'__64_lshift_word'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: *** shift corrected from %d to %d ***'
         DC    X'0'
         DS    0F
* X-func *@@64LSHW prologue
@@64LSHW PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64LSHW code
         L     5,0(11)
         L     3,4(11)
         LR    2,3
         LTR   5,5
         BE    @@L1
         LTR   3,3
         BNL   @@L3
         SLR   2,2
         B     @@L4
@@L3     EQU   *
         L     12,0(,10)
         LA    4,4(0,0)
         CR    3,4
         BNH   @@L4
         LR    2,4
@@L4     EQU   *
         L     12,0(,10)
         CLR   2,3
         BE    @@L5
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         ST    3,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         SLR   4,4
         CR    4,2
         BNL   @@L1
@@L13    EQU   *
         LR    15,5
         LA    3,2(0,0)
@@L12    EQU   *
         MVC   0(2,15),2(15)
         BCTR  3,0
         A     15,=F'2'
         LTR   3,3
         BNL   @@L12
         MVC   6(2,5),=H'0'
         A     4,=F'1'
         CR    4,2
         BL    @@L13
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64LSHW epilogue
         PDPEPIL
* Function *@@64LSHW literal pool
         DS    0F
         LTORG
* Function *@@64LSHW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
