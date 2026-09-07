* USING ist nach BASISREGISTER geschluesselt: eine zweite USING
* auf demselben Register ERSETZT die erste (#177).
*
* Die zweite USING steht ABSICHTLICH oberhalb von A.  Stuende sie
* darunter, gewaenne ohnehin die kleinere Distanz und beide Regeln
* lieferten dasselbe Register -- die Messung entschiede nichts.
*
*   ERSETZEN  (IFOX00)  A liegt unter der einzigen Basis
*                       -> IFO209, rc 8:      0000 0000
*   ANHAENGEN (as370)   der tote T-Eintrag traegt noch
*                       -> stillschweigend:   5810 C000
*
* Die beiden folgenden Faelle sind die Gegenprobe: ein Ersetzen,
* das zu weit greift, faellt hier durch.
T        CSECT
         USING T,12
A        DS    F
HIGH     DS    0H
         USING HIGH,12
         L     1,A
         L     2,HIGH
         DROP  12
         USING T,12
         L     3,A
         BR    14
         END   T
