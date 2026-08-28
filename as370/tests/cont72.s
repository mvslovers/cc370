CONT72   CSECT
* CASE A -- this comment card carries a non-blank in column 72 and the
* next card is a STATEMENT. Does IFOX00 eat it as a continuation?      X
SWALLOW  DC    F'1'
CTLA     DC    F'2'
* CASE B -- same, but the next card is another COMMENT card, which has
* text between the begin and continue columns: IFO026 is expected here.X
* CASE B continuation card -- a comment starting in column 1.
CTLB     DC    F'3'
* CASE C -- three over-long comment cards in a row: two continuations
* are allowed, so the third should draw IFO069 as well as IFO026.      X
* CASE C second card, itself reaching column 72.                       X
* CASE C third card, itself reaching column 72.                        X
CTLC     DC    F'4'
         END
