         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'racf_logout'
* Program text area
         DS    0F
* X-func *RACLGOUT prologue
RACLGOUT PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *RACLGOUT code
         L     4,0(11)
         MVC   104(4,13),=F'0'
         SLR   5,5
         ST    5,168(13)
         L     2,548(5)
         L     6,108(2)
         A     6,=F'200'
         LR    7,4
         LTR   4,4
         BE    @@L3
         L     7,0(4)
@@L3     EQU   *
         L     12,0(,10)
         LA    2,112(,13)
         LA    3,55(0,0)
         XC    0(0,2),0(2)      clear plist *** executed ***
         EX    3,*-6
         MVI   112(13),56
         
*
* See if we're in supervisor state
*
         TESTAUTH FCTN=0,STATE=YES,KEY=NO,RBLEVEL=1
         ST    15,104(13)
         L     2,104(13)
         LTR   2,2
         BNE   @@L5
         LA    5,1(0,0)
         
*
* we're in supervisor state, switch to key 0
*
         IPK   ,
         ST    2,168(13)
         SPKA  0(0)
         B     @@L6
@@L5     EQU   *
         
*
* enter supervisor state
*
         MODESET KEY=ZERO,MODE=SUP

@@L6     EQU   *
         
*
* delete ACEE
*
         RACINIT ENVIR=DELETE,ACEE=(4),MF=(E,112(13))
         ST    15,104(13)
         L     12,0(,10)
         ST    7,172(13)
         ST    6,88(13)
         LA    2,172(,13)
         ST    2,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@CAS)
         BALR  14,15
         LTR   5,5
         BE    @@L7
         L     2,168(13)
         
*
* we're in supervisor state, switch back to callers key
*
         SPKA  0(2)
         B     @@L8
@@L7     EQU   *
         
*
* return to problem state
*
         MODESET KEY=NZERO,MODE=PROB

@@L8     EQU   *
         L     12,0(,10)
         MVC   0(4,4),=F'0'
         L     15,104(13)
* Function *RACLGOUT epilogue
         PDPEPIL
* Function *RACLGOUT literal pool
         DS    0F
         LTORG
* Function *RACLGOUT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
