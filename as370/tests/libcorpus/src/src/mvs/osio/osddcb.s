         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osddcb prologue
OSDDCB   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osddcb code
         L     4,0(11)
         LA    2,96(,13)
         LA    0,PROTOLEN
         ST    0,0(,2)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),96(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         MVC   0(PROTOLEN,15),PROTODCB
         LTR   4,4
         BE    @@L3
         CLI   2(4),122
         BNE   @@L5
         A     4,=F'3'
@@L5     EQU   *
         L     12,0(,10)
         MVC   96(4,13),=F'0'
         SLR   5,5
         IC    2,0(4)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L3
@@L9     EQU   *
         SLR   2,2
         IC    2,0(5,4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,40(15,5)
         L     2,96(13)
         A     2,=F'1'
         ST    2,96(13)
         LR    5,2
         LA    3,7(0,0)
         CR    2,3
         BH    @@L3
         IC    2,0(2,4)
         CLM   2,1,=XL1'00'
         BNE   @@L9
@@L3     EQU   *
         L     12,0(,10)
* Function osddcb epilogue
         PDPEPIL
* Function osddcb literal pool
         DS    0F
         LTORG
* Function osddcb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
* BDAM DCB Prototype for relative record processing
PROTODCB DCB   DDNAME=A,DSORG=DA,MACRF=(RIC,WIC),OPTCD=R
PROTOLEN EQU   *-PROTODCB
         END
