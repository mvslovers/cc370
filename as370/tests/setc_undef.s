* Eine nicht aufloesbare Variablenreferenz in offenem Code
* (#141, Grenze zu #97).
*
* &X ist deklariert und gesetzt, &U nie.  Was macht IFOX aus &U?
*
*   R1  zu leer substituieren    B = C1C2       (AB)
*   R2  woertlich stehenlassen   B = C150E4C2   (A&UB)
*   R3  IFO006, kein Objektcode  B erzeugt NICHTS, RC 8
*
* Die drei sagen verschiedene BYTES voraus, nicht nur RC.
* C zeigt, ob die Assemblierung ueberhaupt weiterlaeuft.
T        CSECT
         LCLC  &X
&X       SETC  'Z'
A        DC    C'A&X.B'
B        DC    C'A&U.B'
C        DC    C'END'
         END
