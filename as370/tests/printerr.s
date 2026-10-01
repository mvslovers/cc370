* PRINT NOGEN / OFF und Anweisungen mit Fehler oder MNOTE (#623).
*   E1  NOGEN: eine erzeugte Anweisung mit Fehler -- gelistet?
*   E2  NOGEN: ein MNOTE aus der Expansion -- gelistet?
*   E3  OFF: eine Anweisung mit Fehler im offenen Code -- gelistet?
*   E4  OFF: ein MNOTE im offenen Code -- gelistet?
         MACRO
&L       BAD   &T
&L       DC    C'X&T'
         DC    A(UNDEF&T)
         DC    C'Y&T'
         MEND
         MACRO
&L       NOTE  &T
&L       DC    C'X&T'
         MNOTE 4,'NOTE &T'
         DC    C'Y&T'
         MEND
TERR     CSECT
         PRINT NOGEN
E1       BAD   1
E2       NOTE  2
         PRINT GEN
         DC    C'G1'
         PRINT OFF
         DC    A(UNDEF3)
         MNOTE 4,'NOTE 4'
         DC    C'O4'
         PRINT ON
         DC    C'G2'
         END
