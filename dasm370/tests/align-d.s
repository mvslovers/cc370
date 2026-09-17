* cc370#385's acceptance, the ALIGNS side.  Read with `align-e.s'.
*
* PAD sits two bytes short of a fullword, so it pads two bytes and
* RESERVES NOTHING.  `align-e.s' is this file with `DS 0F' replaced
* by `DS CL2', which RESERVES two -- and THE TWO DECKS ARE
* BYTE-IDENTICAL.  The run.sh block asserts that, because it is the
* whole point: an object-deck reader has no evidence at all to tell
* these apart, and two defensible object-side rules measured over
* the 30 control CSECTs disagree 1 % against 14 % about the size of
* that population.  Only as370's `reserves' (cc370#411) separates
* them, and #385's acceptance is exactly that the contract does.
*
* `align-f.s' covers those two bytes with data, so each of these
* two references diffs against it into one finding at 000006 and
* the two verdicts can be read side by side.
*
* Keep every line under column 72.
*
ALIGND   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
PAD      DS    0F
         BR    14
VAL      DC    F'1'
         END
