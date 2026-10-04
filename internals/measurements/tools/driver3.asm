* FETCHDR3 -- the strict form of the experiment.
* LOAD / call / DELETE, then DIRTY the freed storage on purpose with a
* GETMAIN of the same size filled with X'DD' and a FREEMAIN, and only
* then LOAD again.  If the hole still reads zero here, program fetch
* itself supplies the zeros; if it reads X'DD', the earlier clean run
* was an artefact of nothing having touched the storage in between.
         PRINT NOGEN
FETCHDR3 CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,DSAVE+4
         LA    15,DSAVE
         ST    15,8(13)
         LR    13,15
*  first load, leaves X'EE' behind
         LOAD  EP=PROBE
         ST    0,EPA
         LR    15,0
         BALR  14,15
         ST    15,RCA
         DELETE EP=PROBE
*  dirty the freed storage deliberately
         L     3,DLEN
         GETMAIN R,LV=(3)
         LR    4,1
         ST    4,DADDR
         L     3,DLEN
DFILL    MVI   0(4),X'DD'
         LA    4,1(,4)
         BCT   3,DFILL
         L     1,DADDR
         L     3,DLEN
         FREEMAIN R,LV=(3),A=(1)
*  load again into storage we know was not zero a moment ago
         LOAD  EP=PROBE
         ST    0,EPB
         LR    15,0
         BALR  14,15
         ST    15,RCB
         DELETE EP=PROBE
*
         L     2,EPA
         C     2,EPB
         BNE   DIFFADR
         L     15,RCB
         LTR   15,15
         BZ    WASZERO
         WTO   'FETCH3DDE HOLE CARRIED NON-ZERO AFTER A DIRTIED FREE'
         LA    15,8
         B     DRET
WASZERO  WTO   'FETCH3OKI HOLE READ ZERO EVEN AFTER A DIRTIED FREE'
         SR    15,15
         B     DRET
DIFFADR  WTO   'FETCH316E LOADS AT DIFFERENT ADDRESSES - INCONCLUSIVE'
         LA    15,16
DRET     L     13,DSAVE+4
         ST    15,16(13)
         L     14,12(13)
         LM    0,12,20(13)
         BR    14
*
DLEN     DC    A(196608)
DADDR    DS    F
EPA      DS    F
EPB      DS    F
RCA      DS    F
RCB      DS    F
DSAVE    DS    18F
         END   FETCHDR3
