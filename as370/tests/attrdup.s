* cc370#184 -- an attribute apostrophe is not a delimiter in a
* parenthesised duplication factor, nor in a macro prototype
* default.  Every line has its control on the line below it,
* written with the plain number 4: the two must produce the
* same bytes, so a wrong answer shows without the oracle.
         MACRO
         PROTO &P=L'FLD
P&SYSNDX DC    AL1(&P)
         MEND
ATTRDUP  CSECT
FLD      DS    CL4
A1       DS    CL(L'FLD)
A2       DS    CL(4)
B1       DC    (L'FLD)C'X'
B2       DC    (4)C'X'
C1       DS    (L'FLD)CL2
C2       DS    (4)CL2
         PROTO
         PROTO P=4
         END
