         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'racf_auth'
* Program text area
         DS    0F
* X-func *RACAUTH prologue
RACAUTH  PDPPRLG CINDEX=0,FRAME=256,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *RACAUTH code
         L     8,4(11)
         L     6,12(11)
         SLR   2,2
         ST    2,248(13)
         ST    2,252(13)
         LA    7,97(,13)
         LA    3,64(0,0)
         LA    4,8(0,0)
         
*** MEMSET ***
         LR    14,7           => target (s)
         LR    15,4           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LA    9,112(,13)
         LA    2,80(0,0)
         
*** MEMSET ***
         LR    14,9           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LA    3,192(,13)
         LA    2,56(0,0)
         SLR   5,5
         
*** MEMSET ***
         LR    14,3           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,5            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LTR   8,8
         BE    @@L5
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         CLR   15,4
         BNH   @@L6
         LR    15,4
@@L6     EQU   *
         L     12,0(,10)
         STC   15,96(13)
         LR    4,7
         LR    5,15
         LR    2,8
         LR    3,15
         MVCL  4,2
@@L5     EQU   *
         L     12,0(,10)
         L     5,8(11)
         LTR   5,5
         BE    @@L7
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,80(0,0)
         CLR   15,2
         BNH   @@L8
         LR    15,2
@@L8     EQU   *
         L     12,0(,10)
         LR    4,9
         LR    5,15
         L     2,8(11)
         LR    3,15
         MVCL  4,2
@@L7     EQU   *
         L     12,0(,10)
         LA    5,4(0,0)
         CR    6,5
         BE    @@L9
         BH    @@L16
         LA    2,2(0,0)
         LTR   6,6
         BNE   @@L22
         B     @@L10
@@L16    EQU   *
         L     12,0(,10)
         LA    5,8(0,0)
         CLR   6,5
         BE    @@L9
         LA    2,128(0,0)
@@L22    EQU   *
         L     12,0(,10)
         CLR   6,2
         BE    @@L9
         B     @@L15
@@L10    EQU   *
         L     12,0(,10)
         LA    6,2(0,0)
         B     @@L9
@@L15    EQU   *
         L     12,0(,10)
         LA    6,128(0,0)
@@L9     EQU   *
         L     12,0(,10)
         OI    196(13),2
         MVI   192(13),56
         MVC   216(4,13),0(11)
         
*
* see if we're in supervisor state
*
         TESTAUTH FCTN=0,STATE=YES,KEY=NO,RBLEVEL=1
         ST    15,248(13)
         L     2,248(13)
         LTR   2,2
         BE    @@L19
         
*
* see if we're APF authorized
*
         TESTAUTH FCTN=1,STATE=NO,KEY=NO,RBLEVEL=1
         ST    15,248(13)
         MVC   252(4,13),=F'0'
         L     2,248(13)
         LTR   2,2
         BNE   @@L19
         MVC   252(4,13),=F'1'
         
*
* enter supervisor state
*
         MODESET KEY=ZERO,MODE=SUP

@@L19    EQU   *
         L     12,0(,10)
         LA    3,112(,13)
         LA    2,96(,13)
         
*
* check access to resource
*
         RACHECK ENTITY=((3)),CLASS=(2),ATTR=(6),MF=(E,192(13))
         ST    15,248(13)
         L     5,252(13)
         LTR   5,5
         BE    @@L20
         
*
* return to problem state
*
         MODESET KEY=NZERO,MODE=PROB

@@L20    EQU   *
         L     12,0(,10)
         L     15,248(13)
* Function *RACAUTH epilogue
         PDPEPIL
* Function *RACAUTH literal pool
         DS    0F
         LTORG
* Function *RACAUTH page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
LISTLOG  RACHECK ENTITY=ENTITY,CLASS='FACILITY',ATTR=READ,LOG=NONE,    X
               MF=L
LISTNOG  RACHECK ENTITY=ENTITY,CLASS='FACILITY',ATTR=READ,             X
               MF=L
ENTITY   DC   CL40'THIS'

         END
