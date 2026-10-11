* A-CON TO A NAME THAT IS BOTH ER (FROM V) AND LD (CC370#919).
* EACH A-CON NAMES ITS TERM.  V() STAYS AGAINST THE ER.
ERLDA    CSECT
         USING ERLDA,15
         EXTRN OUT
         ENTRY LATE,EARLY
VL1      DC    V(LATE)                 ER, V BEFORE DEFINITION
AL1      DC    A(LATE)                 LD, DEFINED LATER
AL2      DC    A(LATE+4)               LD, WITH OFFSET
AL3      DC    AL3(LATE)               LD, 3 BYTES
AL4      L     1,=A(LATE)              LD, LITERAL
AO1      DC    A(OUT)                  ER, CONTROL
ERLDB    CSECT
EARLY    DC    F'0'
LATE     DC    F'1'
VE1      DC    V(EARLY)                ER, V AFTER DEFINITION
AE1      DC    A(EARLY)                LD, DEFINED EARLIER
AB1      DC    A(ERLDB)                SD, CONTROL
         END
