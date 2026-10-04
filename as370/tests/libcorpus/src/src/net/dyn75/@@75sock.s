         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'socket'
* Program text area
         DS    0F
* X-func *@@75SOCK prologue
@@75SOCK PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75SOCK code
         L     3,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LA    4,104(,13)
         XC    0(64,4),0(4)     clear __75 parameter list
         IC    2,10(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BL    @@L2
         LA    1,88(,13)
         L     15,=V(@@75INIT)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLL   3,16
         O     3,4(11)
         ST    3,136(13)
         MVC   140(4,13),8(11)
         MVC   132(4,13),=F'5'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     2,120(13)
         LTR   2,2
         BL    @@L3
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@SOADD)
         BALR  14,15
         B     @@L4
@@L3     EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'0'
         MVC   132(4,13),=F'3'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),120(13)
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@75SOCK epilogue
         PDPEPIL
* Function *@@75SOCK literal pool
         DS    0F
         LTORG
* Function *@@75SOCK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
