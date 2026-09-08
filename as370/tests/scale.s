* Ein SKALIERUNGSMODIFIKATOR multipliziert den Nennwert mit zwei hoch
* der Skala: DC FS3'1.25' ist 1,25 x 8 = 10. as370 las den Nennwert
* mit strtol, das am Dezimalpunkt aufhoert und den Modifikator nicht
* kennt - es speicherte 1 (cc370#217).
*
* Der Fall aus dem Korpus ist DC FS28'6.2832', die Definition von
* zwei Pi in den wissenschaftlichen Routinen mit FORTRAN-Syntax:
* x'6487FCB9' gegen x'00000006'.
*
* Gerundet wird zur NAECHSTEN Zahl, vom Null weg. K3 ist die
* Kontrolle, die das von Abschneiden trennt: 1,2 x 4 ist 4,8, und
* IFOX00 schreibt 5. Ohne diesen Fall waeren beide Regeln gleich
* wahrscheinlich, denn 1,3 x 4 = 5,2 ergibt so wie so 5.
*
* K5 und K6 sind die Kontrollen ohne Modifikator - sie muessen Byte
* fuer Byte gleich bleiben, denn an ihnen haengt der ganze Baum. Der
* Skalenpfad wird nur betreten, wenn ein Modifikator dasteht.
* K7 prueft die Skala null, die den Wert unveraendert laesst.
*
* Punktzahl:  ohne Fix 00000006 0000000A 00000001 00000001 ...
*             mit Fix  6487FCB9 0000000A 00000005 00000005 ...
SCALE    CSECT
K1       DC    FS28'6.2832'
K2       DC    FS3'1.25'
K3       DC    FS2'1.2'
K4       DC    FS2'1.3'
K5       DC    F'10'
K6       DC    H'7'
K7       DC    FS0'7'
K8       DC    FS3'-1.25'
K9       DC    HS4'1.5'
KA       DC    HS14'0.1'
KB       DC    HS14'-0.1'
KC       DC    FS31'0.5'
KD       DC    FS8'0.5'
         END
