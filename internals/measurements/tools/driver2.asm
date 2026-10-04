* FETCHDR2 -- POSITIVE CONTROL for the fill.
* LOAD once, call twice, no DELETE in between.  The second call runs
* against the SAME copy in storage, so it MUST see the X'EE' the first
* call wrote.  RC 8 here proves the fill and the scan both work; RC 0
* here would mean the main experiment's RC 0 proves nothing.
         PRINT NOGEN
FETCHDR2 CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,DSAVE+4
         LA    15,DSAVE
         ST    15,8(13)
         LR    13,15
*
         LOAD  EP=PROBE
         ST    0,EPA
         LR    15,0
         BALR  14,15
         ST    15,RCA
         L     15,EPA
         BALR  14,15
         ST    15,RCB
         DELETE EP=PROBE
*
         L     15,RCA
         LTR   15,15
         BNZ   BADA
         L     15,RCB
         LTR   15,15
         BZ    BADB
         WTO   'FETCH2OKI FILL VERIFIED - SECOND CALL SAW THE MARK'
         SR    15,15
         B     DRET
BADA     WTO   'FETCH2AAE FIRST CALL ALREADY SAW NON-ZERO'
         LA    15,4
         B     DRET
BADB     WTO   'FETCH2BBE SECOND CALL SAW ZERO - FILL OR SCAN BROKEN'
         LA    15,8
DRET     L     13,DSAVE+4
         ST    15,16(13)
         L     14,12(13)
         LM    0,12,20(13)
         BR    14
*
EPA      DS    F
RCA      DS    F
RCB      DS    F
DSAVE    DS    18F
         END   FETCHDR2
