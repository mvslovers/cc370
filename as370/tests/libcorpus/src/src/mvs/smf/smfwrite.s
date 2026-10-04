         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'smf_write'
* Program text area
         DS    0F
* X-func *SMFWRITE prologue
SMFWRITE PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *SMFWRITE code
         L     4,0(11)
         MVC   88(4,13),=F'0'
         SLR   3,3
         LA    1,88(,13)
         L     15,=V(SMFACTIV)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BE    @@L1
         
*
* See if we're in supervisor state
*
         TESTAUTH FCTN=0,STATE=YES,KEY=NO,RBLEVEL=1
         ST    15,88(13)
         L     2,88(13)
         LTR   2,2
         BNE   @@L6
         LA    3,1(0,0)
         B     @@L4
@@L6     EQU   *
         
*
* enter supervisor state
*
         MODESET KEY=ZERO,MODE=SUP

@@L4     EQU   *
         
*
* write SMF record via SVC 83
*
         SLR   0,0
                  LR 1,4
                  SVC 83
                  ST 15,88(13)
         L     12,0(,10)
         LTR   3,3
         BNE   @@L5
         
*
* return to problem state
*
         MODESET KEY=NZERO,MODE=PROB

@@L5     EQU   *
         L     12,0(,10)
         L     2,88(13)
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *SMFWRITE epilogue
         PDPEPIL
* Function *SMFWRITE literal pool
         DS    0F
         LTORG
* Function *SMFWRITE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
