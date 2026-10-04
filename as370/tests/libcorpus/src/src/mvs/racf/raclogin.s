         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'racf_login'
* Program text area
@@LC0    EQU   *
         DC    C'*'
         DC    X'0'
         DS    0F
* X-func *RACLOGIN prologue
RACLOGIN PDPPRLG CINDEX=0,FRAME=216,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *RACLOGIN code
         L     4,0(11)
         L     6,4(11)
         L     5,8(11)
         L     8,12(11)
         MVC   96(4,13),=F'0'
         MVC   208(4,13),=F'0'
         SLR   7,7
         LA    3,152(,13)
         LA    2,55(0,0)
         XC    0(0,3),0(3)      clear plist *** executed ***
         EX    2,*-6
         MVI   152(13),56
         LTR   4,4
         BNE   @@L2
         L     4,=A(@@LC0)
@@L2     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L3
         LR    15,2
@@L3     EQU   *
         L     12,0(,10)
         STC   15,104(13)
         LTR   15,15
         BNH   @@L4
         LA    2,105(,13)
         MVC   0(8,2),=CL8' '   clear userid to spaces
         LA    2,105(,13)
         BCTR  15,0
         MVC   0(0,2),0(4)     copy userid *** executed ***
         EX    15,*-6
         LA    2,105(,13)
         OC    0(8,2),=CL8' '    fold to upper case
@@L4     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L5
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L6
         LR    15,2
@@L6     EQU   *
         L     12,0(,10)
         STC   15,120(13)
         LTR   15,15
         BNH   @@L5
         LA    2,121(,13)
         MVC   0(8,2),=CL8' '   clear password to spaces
         LA    2,121(,13)
         BCTR  15,0
         MVC   0(0,2),0(6)     copy password *** executed ***
         EX    15,*-6
         LA    2,121(,13)
         OC    0(8,2),=CL8' '    fold to upper case
@@L5     EQU   *
         L     12,0(,10)
         LR    15,5
         LTR   5,5
         BE    @@L10
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L10
         LR    15,2
@@L10    EQU   *
         L     12,0(,10)
         STC   15,136(13)
         LTR   15,15
         BNH   @@L11
         LA    2,137(,13)
         MVC   0(8,2),=CL8' '   clear group to spaces
         LA    2,137(,13)
         BCTR  15,0
         MVC   0(0,2),0(5)     copy group *** executed ***
         EX    15,*-6
         LA    2,137(,13)
         OC    0(8,2),=CL8' '    fold to upper case
         LA    5,136(,13)
@@L11    EQU   *
         
*
* See if we're in supervisor state
*
         TESTAUTH FCTN=0,STATE=YES,KEY=NO,RBLEVEL=1
         ST    15,96(13)
         L     12,0(,10)
         L     2,96(13)
         LTR   2,2
         BNE   @@L18
         LA    7,1(0,0)
         B     @@L13
@@L18    EQU   *
         
*
* enter supervisor state
*
         MODESET KEY=ZERO,MODE=SUP

@@L13    EQU   *
         L     12,0(,10)
         LA    4,104(,13)
         LA    3,208(,13)
         LTR   6,6
         BE    @@L14
         LA    2,120(,13)
         
*
* create ACEE for this user and password
*
         RACINIT ENVIR=CREATE,                                         X
               ACEE=(3),USERID=(4),PASSWRD=(2),GROUP=(5),MF=(E,152(13))
         ST    15,96(13)
         B     @@L15
@@L14    EQU   *
         
*
* create ACEE for this user (no password)
*
         RACINIT ENVIR=CREATE,PASSCHK=NO,                              X
               ACEE=(3),USERID=(4),GROUP=(5),MF=(E,152(13))
         ST    15,96(13)
@@L15    EQU   *
         L     12,0(,10)
         LTR   7,7
         BNE   @@L16
         
*
* return to problem state
*
         MODESET KEY=NZERO,MODE=PROB

@@L16    EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L17
         MVC   0(4,8),96(13)
@@L17    EQU   *
         L     12,0(,10)
         L     15,208(13)
* Function *RACLOGIN epilogue
         PDPEPIL
* Function *RACLOGIN literal pool
         DS    0F
         LTORG
* Function *RACLOGIN page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
