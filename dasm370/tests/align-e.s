* cc370#385's acceptance, the RESERVES side.  Read with `align-d.s'.
*
* This is `align-d.s' with `PAD DS 0F' replaced by `HOLD DS CL2'.
* HOLD occupies its two bytes; PAD only aligned over them.  The two
* decks are BYTE-IDENTICAL -- run.sh asserts it -- so the object
* carries no evidence whatsoever for the distinction, and only the
* statement export can answer it.
*
ALIGND   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
HOLD     DS    CL2
         BR    14
VAL      DC    F'1'
         END
