* Ein UNDEFINIERTES Symbol ist keine absolute Domaene (#190).
*
* Es wertet zu 0 und nicht-relokierbar aus, genau wie ein
* absolutes Symbol.  Nimmt man das fuer eine absolute USING,
* bekommt jeder absolute Operand des Moduls eine Basis:
* IFFAAA01 bildet GSPCB aus einem Makro ab, das wir nicht haben,
* und `L 6,16' adressierte dann R5+16 statt absolut 16 -- den
* CVT-Zeiger.  52 Decks verloren daran ihre Identitaet.
*
* IFOX00 meldet das undefinierte Symbol (rc 12) und setzt den
* Operanden mit Basis 0 ab:  5860 0010, nicht 5860 5010.
* Darum ein eigenes Modul: bei rc 12 wird kein Deck geschrieben,
* die Pruefung laeuft ueber das Listing.
T        CSECT
         USING UNDEF,5
         L     6,16
         BR    14
         END   T
