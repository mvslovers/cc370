* Basisregisterwahl bei mehreren aktiven USING (#138).
*
* Gemessen gegen IFOX00: die kleinste Distanz gewinnt, und bei
* GLEICHER Distanz das HOECHSTNUMMERIERTE Register.
*
*   L 1,A   5810 B00C   Basis 11 gegen 10, gleiche Distanz
*   L 2,B   5820 C000   Basis 12 gegen 9,  gleiche Distanz
*   L 3,A   5830 C008   Basis 12 gibt 008, Basis 11 gaebe 00C
*
* Die dritte Zeile trennt die Distanzregel von der Gleichstands-
* regel: dort ist die Distanz NICHT gleich, und beide Assembler
* nehmen die kleinere.  as370 nahm bei Gleichstand den zuerst
* registrierten Eintrag, weil using_for auf `dd < bd` prueft.
T        CSECT
         USING T,10
         USING T,11
         L     1,A
B        EQU   *
         USING B,9
         USING B,12
         L     2,B
         L     3,A
A        DS    F
         END
