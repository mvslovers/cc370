* cc370#384: the reference side of the two constructed cases.
*
* CASE 1 is `align-b.s': ONE four-byte insertion.  It exists for the
* thing #112 got wrong -- the shift at 000002 PRECEDES its cause,
* because `L 2,VAL' addresses data at the end of the section and an
* insertion anywhere before that data moves it.  So position relative
* to the change is not evidence, and the classifier must not use it.
*
* CASE 2 is `align-c.s': insertions of TWO and FOUR bytes that move
* every displacement by EIGHT.  The other two bytes are alignment
* padding -- the 2-byte insertion pushes the data area off its
* fullword boundary and the assembler makes it up.  A prefix sum over
* the detected code insertions gives 6, so a classifier built that way
* reports EVERY displacement in the module as a constant change: a
* whole module of findings where there are none.
*
* Keep every line under column 72.
*
ALIGNX   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
         A     2,VAL2
         ST    2,VAL
         L     3,VAL2
         BR    14
VAL      DC    F'1'
VAL2     DC    F'2'
         END
