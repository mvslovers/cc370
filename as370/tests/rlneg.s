* NEGATIVE RELOCATION TERMS (CC370#824).  EACH A-CON NAMES ITS TERMS.
RLNEG    CSECT
         EXTRN X
NEG1     DC    A(-RLNEG)               -RLNEG
NEG2     DC    A(10-RLNEG)             -RLNEG
NEG3     DC    A(X-RLNEG)              +X -RLNEG
NEG4     DC    A(-X)                   -X
NEG5     DC    A(-RLNEG+X)             -RLNEG +X
NEG6     DC    A(RLNEG-X)              +RLNEG -X
NEG7     DC    AL3(-X)                 -X, 3 BYTES
NEG8     DC    A(X)                    +X, CONTROL
NEG9     DC    A(RLNEG)                +RLNEG, CONTROL
         END
