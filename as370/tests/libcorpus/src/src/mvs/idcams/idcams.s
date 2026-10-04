         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'idcams'
* Program text area
         DS    0F
* X-func idcams prologue
IDCAMS   PDPPRLG CINDEX=0,FRAME=360,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function idcams code
         LA    15,4(,11)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'256'
         MVC   96(4,13),0(11)
         ST    15,100(13)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         SLR   15,15
         STC   15,359(13)
         ST    2,88(13)
         ST    15,92(13)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
* Function idcams epilogue
         PDPEPIL
* Function idcams literal pool
         DS    0F
         LTORG
* Function idcams page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'idcams_sysprint'
         DS    0F
* X-func *IDCSYSPR prologue
IDCSYSPR PDPPRLG CINDEX=1,FRAME=360,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function *IDCSYSPR code
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'256'
         MVC   96(4,13),8(11)
         LA    2,12(,11)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         MVI   359(13),0
         ST    3,88(13)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
* Function *IDCSYSPR epilogue
         PDPEPIL
* Function *IDCSYSPR literal pool
         DS    0F
         LTORG
* Function *IDCSYSPR page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         DS    0H
@V1      EQU   *
         DC    X'0000'
         
&FUNC    SETC 'link_idcams'
@@LC0    EQU   *
         DC    C'DDSYSIN   '
         DC    X'0'
@@LC1    EQU   *
         DC    C'DDSYSPRINT'
         DC    X'0'
@@LC2    EQU   *
         DC    C'IDCAMS'
         DC    X'0'
         DS    0F
* Function link_idcams,F6 prologue
@@F6     PDPPRLG CINDEX=2,FRAME=8240,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function link_idcams code
         L     2,=A(@@LC0)
         MVC   104(10,13),0(2)
         L     2,=A(@@LC1)
         MVC   120(10,13),0(2)
         LA    3,136(,13)
         LR    6,3
         L     7,=F'8000'
         SLR   4,4
         LR    5,4
         MVCL  6,4
         L     2,=F'8032'
         ST    3,104(13,2)
         L     3,0(11)
         ST    3,108(2,13)
         L     3,4(11)
         ST    3,112(2,13)
         L     3,8(11)
         ST    3,116(2,13)
         L     3,=F'8048'
         LA    2,104(,13)
         ST    2,104(13,3)
         L     2,=V(@@IDCEX)
         ST    2,108(3,13)
         L     4,=F'8136'
         AR    4,13
         ST    4,112(3,13)
         A     3,=F'16'
         LA    2,120(,13)
         ST    2,104(13,3)
         L     2,=V(@@IDCEX)
         ST    2,108(3,13)
         ST    4,112(3,13)
         L     2,=F'8080'
         LA    3,2(0,0)
         ST    3,104(13,2)
         L     3,=F'8152'
         AR    3,13
         L     2,=F'8188'
         AR    2,13
         MVC   0(12,2),0(3)
         L     3,=F'8168'
         AR    3,13
         L     2,=F'8200'
         AR    2,13
         MVC   0(12,2),0(3)
         L     4,=F'8232'
         AR    4,13
         MVC   0(4,4),=F'0'
         L     2,=F'8112'
         L     3,=A(@V1)
         ST    3,104(13,2)
         ST    3,108(2,13)
         ST    3,112(2,13)
         L     3,=F'-2147475464'
         AR    3,13
         ST    3,116(2,13)
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=F'0'
         L     2,=F'8216'
         AR    2,13
         ST    2,96(13)
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(@@LINKDS)
         BALR  14,15
         LTR   15,15
         BNH   @@L4
         LCR   2,15
         ST    2,0(4)
@@L4     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNL   @@L6
         ST    15,0(4)
@@L6     EQU   *
         L     12,0(,10)
         L     15,0(4)
* Function link_idcams epilogue
         PDPEPIL
* Function link_idcams literal pool
         DS    0F
         LTORG
* Function link_idcams page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         ENTRY @@IDCEX
@@IDCEX  DS    0H
         SAVE  (14,12),,@@IDCEX
         LA    12,0(,15)           base register
         USING @@IDCEX,12          base register
         L     14,0(,1)            A(UDATA)
         L     15,0(,14)           A(NAB in C stack frame)
         ST    13,4(,15)           backward chain (prev)
         ST    15,8(,13)           forward chain (next)
         LR    13,15               our stack frame
         LA    15,88(,15)          minimal stack frame
         ST    15,76(13)           next available byte
* Now call our idcams io exit
         L     15,=A(@@IDCEXC)     A(__idcexc)
         BALR  14,15               call our C function
         L     13,4(,13)           get prev stack frame
         RETURN (14,12),RC=(15)    restore regs and return
         LTORG ,                   our literal pool
         DROP  12                  drop base register
         DS    0F
* Function idc_number,F7 prologue
@@F7     PDPPRLG CINDEX=3,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function idc_number code
         L     5,0(11)
         SLR   15,15
         L     2,4(11)
         LA    3,8(0,0)
         CR    2,3
         BNH   @@L17
         CLI   1(5),201
         BNE   @@L17
         CLI   2(5),196
         BNE   @@L17
         CLI   3(5),195
         BE    @@L8
@@L17    EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         LA    4,4(0,0)
@@L14    EQU   *
         IC    3,0(4,5)
         LA    2,16(,3)
         CLM   2,1,=XL1'09'
         BH    @@L17
         LR    2,15
         SLL   2,3
         AR    2,15
         AR    15,2
         LR    2,3
         N     2,=XL4'000000FF'
         AR    15,2
         A     15,=F'-240'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BNH   @@L14
@@L7     EQU   *
         L     12,0(,10)
* Function idc_number epilogue
         PDPEPIL
* Function idc_number literal pool
         DS    0F
         LTORG
* Function idc_number page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC '__idcexc'
         DS    0F
* X-func __idcexc prologue
@@IDCEXC PDPPRLG CINDEX=4,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function __idcexc code
         L     3,0(11)
         L     4,8(11)
         SLR   5,5
         L     2,4(11)
         SLR   6,6
         IC    6,0(2)
         LR    2,6
         LA    6,8(0,0)
         CLR   2,6
         BE    @@L22
         LA    6,12(0,0)
         CLR   2,6
         BE    @@L26
         B     @@L19
@@L22    EQU   *
         L     12,0(,10)
         MVC   0(4,4),4(3)
         L     2,4(3)
         LR    15,5
         LTR   2,2
         BE    @@L24
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L24    EQU   *
         L     12,0(,10)
         ST    15,4(4)
         L     2,4(3)
         LTR   2,2
         BNE   @@L25
         LA    5,4(0,0)
@@L25    EQU   *
         L     12,0(,10)
         MVC   4(4,3),=F'0'
         B     @@L19
@@L26    EQU   *
         L     12,0(,10)
         L     2,8(3)
         LTR   2,2
         BE    @@L19
         MVC   88(4,13),0(4)
         MVC   92(4,13),4(4)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         MVC   88(4,13),12(3)
         ST    15,92(13)
         MVC   96(4,13),0(4)
         MVC   100(4,13),4(4)
         L     2,8(3)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
@@L19    EQU   *
         L     12,0(,10)
         LR    15,5
* Function __idcexc epilogue
         PDPEPIL
* Function __idcexc literal pool
         DS    0F
         LTORG
* Function __idcexc page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         END
