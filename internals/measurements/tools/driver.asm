* FETCHDRV -- LOAD / call / DELETE / LOAD / call, the shape a resident
* server repeats all day.  Reports whether the second load saw its own
* predecessor's bytes in what is, to it, uninitialised static storage.
*
* RC 0  = the area was zero on the second load
* RC 8  = it carried the previous load's X'EE'
* RC 16 = the two loads landed at different addresses; says nothing
         PRINT NOGEN
FETCHDRV CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,DSAVE+4
         LA    15,DSAVE
         ST    15,8(13)
         LR    13,15
*
         LOAD  EP=PROBE
         ST    0,ADDR1
         LR    15,0
         BALR  14,15
         ST    15,RC1
         DELETE EP=PROBE
*
         LOAD  EP=PROBE
         ST    0,ADDR2
         LR    15,0
         BALR  14,15
         ST    15,RC2
         DELETE EP=PROBE
*
         L     2,ADDR1
         C     2,ADDR2
         BNE   DIFFADR
         L     15,RC2
         LTR   15,15
         BZ    WASZERO
         WTO   'FETCH001I SECOND LOAD SAW NON-ZERO IN AN ELIDED AREA'
         LA    15,8
         B     DRET
WASZERO  WTO   'FETCH000I SECOND LOAD SAW AN ALL-ZERO AREA'
         SR    15,15
         B     DRET
DIFFADR  WTO   'FETCH016I LOADS AT DIFFERENT ADDRESSES - INCONCLUSIVE'
         LA    15,16
DRET     L     13,DSAVE+4
         ST    15,16(13)
         L     14,12(13)
         LM    0,12,20(13)
         BR    14
*
ADDR1    DS    F
ADDR2    DS    F
RC1      DS    F
RC2      DS    F
DSAVE    DS    18F
         END   FETCHDRV
