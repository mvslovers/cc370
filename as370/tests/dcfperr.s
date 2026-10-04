* FLOATING-POINT RANGE AND MODIFIER LIMITS (CC370#783, #761, #782).
* IFOX00 IS EXPECTED TO END RC 8; EACH REMARK SAYS WHAT IS ASKED.
DCFPERR  CSECT
EMAX     DC    E'7.2E75'               LARGEST, IN RANGE
EOV      DC    E'7.3E75'               JUST OVER
EOVN     DC    E'-1E76'                NEGATIVE OVERFLOW
DOV      DC    D'1E76'                 LONG
LOV      DC    L'1E76'                 EXTENDED, BOTH HALVES
DMIN     DC    D'5.4E-79'              SMALLEST NORMALISED, IN RANGE
DUN      DC    D'5.3E-79'              JUST UNDER
EUN      DC    E'1E-80'                UNDERFLOW
LUN      DC    L'1E-80'                EXTENDED UNDERFLOW
EUNN     DC    E'-1E-80'               NEGATIVE UNDERFLOW
ESBIG    DC    ES15'1.5'               SCALE OVER 14
ESNEG    DC    ES-1'1.5'               NEGATIVE SCALE ON E
FEBIG    DC    FE76'1'                 EXPONENT OVER 75
FENEG    DC    FE-86'1'                EXPONENT UNDER -85
FEMIN    DC    FE-85'1'                EXPONENT -85, IN RANGE
EE75     DC    EE75'1'                 1E75 VIA THE MODIFIER
EE1OV    DC    EE1'1E75'               1E76 VIA THE MODIFIER
FEOV     DC    FE10'1'                 FIXED OVERFLOW VIA E
         END
