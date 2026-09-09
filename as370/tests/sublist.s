* T' einer SUBLISTE antwortet mit dem Typattribut ihres ERSTEN
* ELEMENTS - und steigt nicht weiter ab: ein erstes Element, das
* selbst eine Sublist ist, gibt U (cc370#260).
*
* as370 antwortete fuer jede Sublist U. APVTMACS(HEXCNVT) prueft
*
*     AIF   (T'&OUT NE 'N').ERROR4
*
* und ein Aufruf so gewoehnlich wie `HEXCNVT (3),(2),4' nahm damit den
* Fehlerpfad. Sechs AMDPR*-Module, und IFOX00 assembliert alle sechs
* ohne ein Wort.
*
* Die Grenze ist nicht erratbar, deshalb steht sie vollstaendig hier:
*
*   U1  (3)         N    einelementige Liste
*   U2  (3,4)       N    mehrelementig - das ERSTE zaehlt
*   U3  (FLD)       C    also nicht immer N
*   U4  (FLD,3)     C    das erste, nicht das letzte
*   U5  (3,FLD)     N    und andersherum
*   U6  (,3)        O    ausgelassenes erstes Element
*   U7  (X'0A')     N    selbstdefinierender Term
*   U8  (NODEF)     U    unbekanntes Symbol
*   U9  ((1,2),3)   U    KEIN Abstieg - sonst waere es N
*
* U3 bis U5 sind die Kontrollen gegen "eine Sublist ist immer N",
* U9 gegen "steig in die erste Klammer hinein", U6 gegen "nimm das
* erste nicht leere". Ohne U9 waeren Abstieg und Nicht-Abstieg gleich
* gut vereinbar, denn (1,2) gaebe abgestiegen ebenfalls N.
*
* Punktzahl:  ohne Fix U U C U N O N U U
*             mit Fix  N N C C N O N U U
         MACRO
         QU    &P
         LCLC  &T
&T       SETC  T'&P
         DC    C'&T'
         MEND
SUBLIST  CSECT
FLD      DS    CL4
U1       QU    (3)
U2       QU    (3,4)
U3       QU    (FLD)
U4       QU    (FLD,3)
U5       QU    (3,FLD)
U6       QU    (,3)
U7       QU    (X'0A')
U8       QU    (NODEF)
U9       QU    ((1,2),3)
UA       QU    4
UB       QU    FLD
         END
