* Faltung von '&&' ZUSAMMEN mit Substitution (#141, Kopplung).
*
* amp_fold.s hat gezeigt: die DC-Verarbeitung faltet '&&' immer,
* ganz ohne Variablensymbol.  Offene Frage: faltet der
* SUBSTITUIERER es ebenfalls?  Dann wird zweimal gefaltet.
*
*   Regel A  Substituierer laesst '&&' stehen, nur DC faltet
*              B = 5050E9   drei Bytes
*   Regel B  beide falten
*              B = 50E9     zwei Bytes
*
* as370 faltet heute im msub und NICHT im DC -- die beiden Fehler
* heben einander auf.  Wird nur einer repariert, bricht der andere.
* D ist die Kontrolle aus amp_fold: offener Code, keine
* Substitution, zwei Bytes.
         MACRO
         MM    &V
A        DC    C'&&&V'
B        DC    C'&&&&&V'
         MEND
T        CSECT
         MM    Z
D        DC    C'&&&&'
         END
