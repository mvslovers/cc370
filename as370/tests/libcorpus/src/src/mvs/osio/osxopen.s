         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osxopen prologue
OSXOPEN  PDPPRLG CINDEX=0,FRAME=288,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osxopen code
         L     6,0(11)
         LA    4,104(,13)
         LA    5,176(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         MVC   88(4,13),=A(@@F2)
         ST    6,92(13)
         MVC   96(4,13),4(11)
         LA    2,280(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         IC    2,48(6)
         N     2,=F'16'
         LTR   2,2
         BNE   @@L2
         MVC   280(4,13),=F'8'
@@L2     EQU   *
         L     12,0(,10)
         L     2,280(13)
         LTR   2,2
         BNE   @@L4
         ST    6,88(13)
         LA    2,104(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(RDJFCB)
         BALR  14,15
         MVC   62(2,6),206(13)
         MVC   82(2,6),208(13)
@@L4     EQU   *
         L     12,0(,10)
         L     15,280(13)
* Function osxopen epilogue
         PDPEPIL
* Function osxopen literal pool
         DS    0F
         LTORG
* Function osxopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'opendcb'
         DS    0F
* Function opendcb,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function opendcb code
         L     4,8(11)
         L     2,0(11)
         O     2,=F'-2080374784'
         ST    2,88(13)
         LA    3,88(,13)
         L     2,4(11)
         LTR   2,2
         BNE   @@L6
         LR    1,3
         SVC   19         OPEN
         ST    15,0(,4)
         B     @@L5
@@L6     EQU   *
         LR    1,3
         SVC   22         OPENJ
         ST    15,0(,4)
@@L5     EQU   *
         L     12,0(,10)
* Function opendcb epilogue
         PDPEPIL
* Function opendcb literal pool
         DS    0F
         LTORG
* Function opendcb page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
