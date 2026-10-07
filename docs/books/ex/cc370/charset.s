         COPY  PDPTOP
         CSECT
* X-var nl
         ENTRY NL
* Program data area
NL       EQU   *
         DC    X'15'
* X-var lb
         ENTRY LB
LB       EQU   *
         DC    X'BA'
* Program text area
@@LC0    EQU   *
         DC    C'caf'
         DC    X'51'
         DC    C' '
         DC    X'50'
         DC    C' '
         DC    X'41'
         DC    X'15'
         DC    X'0'
* X-var s
         ENTRY S
* Program data area
         DS    0F
S        EQU   *
         DC    A(@@LC0)
         END
