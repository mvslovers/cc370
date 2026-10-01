* PRINT GEN, NOGEN, ON, OFF, PUSH und POP im Listing (#623).
*
* Jeder Fall erzeugt DC-Konstanten mit eigenem Text, damit im
* Listing zu sehen ist, welche Zeilen erscheinen:
*   P1  NOGEN: der Aufruf erscheint, die Expansion nicht
*   P2  NOGEN, verschachtelt: der innere Aufruf erscheint nicht
*   P5  PRINT NOGEN im Makrorumpf: wirkt es auf den Rest der
*       eigenen Expansion, erscheint das PRINT selbst, und gilt es
*       nach dem Aufruf weiter
*   P6  PUSH PRINT und POP PRINT stellen GEN wieder her
*   P7  PRINT OFF / ON: erscheinen die beiden PRINT-Zeilen
*   P8  PRINT ON,NOGEN in einer Anweisung
         MACRO
&L       INNER &T
&L       DC    C'I&T'
         MEND
         MACRO
&L       OUTER &T
&L       DC    C'O&T'
         INNER &T
         DC    C'Z&T'
         MEND
         MACRO
&L       SELFNG &T
         DC    C'A&T'
         PRINT NOGEN
         DC    C'B&T'
         MEND
TPRT     CSECT
         DC    C'G0'
         PRINT NOGEN
P1       INNER 1
P2       OUTER 2
         PRINT GEN
P2G      OUTER 3
P5       SELFNG 5
P5N      INNER 6
         PRINT GEN
         PUSH  PRINT
         PRINT NOGEN
P6N      INNER 7
         POP   PRINT
P6G      INNER 8
         PRINT OFF
         DC    C'OF'
P7       INNER 9
         PRINT ON
         DC    C'ON'
         PRINT ON,NOGEN
P8       INNER A
         PRINT GEN
         DC    C'G9'
         END
