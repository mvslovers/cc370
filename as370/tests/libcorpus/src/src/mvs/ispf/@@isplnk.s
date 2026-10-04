         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'isplink'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: Missing service name.'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s: Missing hit order bit in plist.'
         DC    X'0'
         DS    0F
* X-func *@@ISPLNK prologue
@@ISPLNK PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ISPLNK code
         MVC   100(4,13),=F'20'
         L     2,0(11)
         LTR   2,2
         BNE   @@L2
         MVC   88(4,13),=A(@@LC0)
         B     @@L11
@@L2     EQU   *
         ST    11,96(13)
         L     12,0(,10)
         SLR   3,3
         L     15,96(13)
@@L8     EQU   *
         L     2,0(15)
         LTR   2,2
         BL    @@L5
         A     3,=F'1'
         A     15,=F'4'
         LA    2,19(0,0)
         CR    3,2
         BNH   @@L8
@@L5     EQU   *
         L     12,0(,10)
         LA    2,20(0,0)
         CLR   3,2
         BNE   @@L9
         MVC   88(4,13),=A(@@LC1)
@@L11    EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L3
@@L9     EQU   *
         LR    1,11           parameter list
         L     15,=V(ISPLINK)
         BALR  14,15          call ISPLINK
         ST    15,100(13)      save return code
@@L3     EQU   *
         L     12,0(,10)
         L     15,100(13)
* Function *@@ISPLNK epilogue
         PDPEPIL
* Function *@@ISPLNK literal pool
         DS    0F
         LTORG
* Function *@@ISPLNK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
