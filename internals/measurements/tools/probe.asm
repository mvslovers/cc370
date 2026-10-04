* PROBE -- is a hole in a loaded module zero?
*
* On entry: count the non-zero bytes in WORK, then fill WORK with X'EE'
* and return.  WORK is a DS reservation, so with ld370's elision the
* module carries no text record for it and program fetch writes nothing
* there.  Loading PROBE twice into the same storage therefore asks the
* question directly: does the X'EE' this run wrote survive into the nex
* load's view of its own uninitialised static area?
*
* RC 0 = every byte was zero    RC 8 = at least one byte was not
         PRINT NOGEN
PROBE    CSECT
         STM   14,12,12(13)
         BALR  12,0
         USING *,12
         ST    13,PSAVE+4
         LA    15,PSAVE
         ST    15,8(13)
         LR    13,15
*  count non-zero bytes in WORK
         LA    2,WORK
         L     3,WLEN
         SR    6,6
SCAN     CLI   0(2),X'00'
         BE    SCANNX
         LA    6,1(,6)
SCANNX   LA    2,1(,2)
         BCT   3,SCAN
*  leave a mark for the next load to find
         LA    2,WORK
         L     3,WLEN
FILL     MVI   0(2),X'EE'
         LA    2,1(,2)
         BCT   3,FILL
*  RC 0 if the area came in clean, 8 if it did not
         LTR   6,6
         BZ    RCZERO
         LA    15,8
         B     PRET
RCZERO   SR    15,15
PRET     L     13,PSAVE+4
         L     14,12(13)
         LM    0,12,20(13)
         BR    14
*
WLEN     DC    A(WKLEN)
PSAVE    DS    18F
         DS    0D
WORK     DS    XL131072
WKLEN    EQU   131072
         END   PROBE
