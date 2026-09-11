* cc370#362: IFOX00 raises IFO217 on 155 USING statements in the
* corpus, and every one of them has BOTH properties at once -- an
* undefined operand AND, potentially, a complex one. The corpus
* cannot separate them. Six cases, and the pairs that decide it are
* 1-against-2 and 3-against-4.
*
* Predictions, written before the oracle was asked. All six, the
* controls included: a control nobody predicted cannot surprise you.
*
*   1 USING UNDEF,2       predict IFO188 + IFO217   the corpus shape
*   2 USING DEFINED,3     predict SILENT            control
*   3 USING DEFINED*2,4   predict IFO217   the #363 rule, on USING
*   4 USING FLDA+FLDB,5   predict IFO213   two sections, as above
*   5 USING *,6           predict SILENT            control
*   6 USING 4096,7        predict SILENT            absolute USING
*
* MEASURED, MVSTK5-REF JOB00036. Three statements flagged, severity 12:
*   1 IFO188 + IFO217        as predicted
*   2 silent                 as predicted
*   3 IFO217, TWICE          predicted once; it flags per base register
*   4 IFO217, not IFO213     PREDICTION WRONG
*   5 silent                 as predicted
*   6 silent                 as predicted
*
* THE ANSWER: case 3 flags, so the 155 corpus sites are NOT merely an
* undefined-symbol diagnostic wearing IFO217's number. The
* relocatability rule applies on the USING path too, and ONE check
* covers both -- the work is to reach that path.
*
* AND A DIFFERENCE BETWEEN THE TWO PATHS, which is the half I got
* wrong: on a USING, IFOX00 answers IFO217 for EVERYTHING, including
* the two-section sum that gives IFO213 in a machine operand
* (tests/relocerr.s). So the message is chosen by the STATEMENT, not
* only by the shape of the expression. A fix that reused #363's
* classifier unchanged would put IFO213 on case 4 and be wrong in
* exactly the way that passes every other check.
A1       CSECT
FLDA     DS    F
B1       CSECT
FLDB     DS    F
T        CSECT
DEFINED  DS    F
         USING UNDEF,2      1: undefined, otherwise simple
         USING DEFINED,3    2: defined and simple -- control
         USING DEFINED*2,4  3: defined, relocatable across a multiply
         USING FLDA+FLDB,5  4: defined, two sections, complex
         USING *,6          5: the location counter -- control
         USING 4096,7       6: absolute -- control
         END
