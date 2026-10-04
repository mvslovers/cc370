         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* Function collect,F2 prologue
@@F2     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function collect code
         L     3,0(11)
         L     7,4(11)
         IC    6,11(7)
         N     6,=F'31'
         AR    6,6
         A     6,=F'12'
         MVC   88(4,13),=F'1'
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L3
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L2
@@L3     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   4(4,3),=F'1'
         LA    15,1(0,0)
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LR    4,2
         LR    5,6
         LR    2,7
         LR    3,6
         MVCL  4,2
@@L1     EQU   *
         L     12,0(,10)
* Function collect epilogue
         PDPEPIL
* Function collect literal pool
         DS    0F
         LTORG
* Function collect page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func __listpd prologue
@@LISTPD PDPPRLG CINDEX=1,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __listpd code
         MVC   104(8,13),=XL8'0000000000000000'
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),=A(@@F2)
         LA    3,104(,13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@WALKPD)
         BALR  14,15
         LTR   15,15
         BL    @@L6
         L     2,108(13)
         LTR   2,2
         BE    @@L5
@@L6     EQU   *
         L     12,0(,10)
         LR    4,3
         LA    3,12(0,0)
         L     2,108(13)
         LTR   2,2
         BNE   @@L8
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     3,0(15)
@@L8     EQU   *
         L     12,0(,10)
         L     2,104(13)
         LTR   2,2
         BE    @@L9
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FREEPD)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    3,0(15)
         SLR   15,15
         B     @@L4
@@L5     EQU   *
         L     12,0(,10)
         L     15,104(13)
@@L4     EQU   *
         L     12,0(,10)
* Function __listpd epilogue
         PDPEPIL
* Function __listpd literal pool
         DS    0F
         LTORG
* Function __listpd page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
