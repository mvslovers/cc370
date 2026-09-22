* FETCHDR4 -- the faithful form.  Dirty the storage through program
* fetch itself, not through a region GETMAIN that may draw on another
* subpool entirely.
*
* PROBEB is the SAME module linked with the text fully materialised;
* PROBE is the sparse one.  Same extent, so the second load is very
* likely to land in the storage the first one just released.  PROBEB's
* own run fills its work area with X'EE' before it is deleted.
         PRINT NOGEN
FETCHDR4 CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,DSAVE+4
         LA    15,DSAVE
         ST    15,8(13)
         LR    13,15
*  dirty: load the materialised twin, let it write X'EE', release it
         LOAD  EP=PROBEB
         ST    0,EPA
         LR    15,0
         BALR  14,15
         ST    15,RCA
         DELETE EP=PROBEB
*  measure: load the sparse one into what that just freed
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
         WTO   'FETCH4EEE SPARSE LOAD SAW THE TWIN-S X-EE- MARK'
         LA    15,8
         B     DRET
WASZERO  WTO   'FETCH4OKI SPARSE LOAD READ ZERO OVER A DIRTIED AREA'
         SR    15,15
         B     DRET
DIFFADR  WTO   'FETCH416E LOADS AT DIFFERENT ADDRESSES - INCONCLUSIVE'
         LA    15,16
DRET     L     13,DSAVE+4
         ST    15,16(13)
         L     14,12(13)
         LM    0,12,20(13)
         BR    14
*
EPA      DS    F
EPB      DS    F
RCA      DS    F
RCB      DS    F
DSAVE    DS    18F
         END   FETCHDR4
