* Trennt "hoechstnummeriert" von "zuletzt registriert" (#138).
*
* In basereg.s stehen die USING aufsteigend, dort liefern beide
* Regeln dasselbe Register -- die Messung entscheidet nichts.
* Hier stehen sie ABSTEIGEND:
*
*   Basis 11 -> hoechstnummeriert gewinnt   (IFOX00: 5810 B004)
*   Basis 10 -> zuletzt registriert gewinnt
*
* IFOX nimmt 11, obwohl 10 zuletzt registriert wurde.  Ein Fix,
* der `dd < bd` nur zu `dd <= bd` macht, implementiert "zuletzt
* registriert" und faellt genau hier durch.
T        CSECT
         USING T,11
         USING T,10
         L     1,A
A        DS    F
         END
