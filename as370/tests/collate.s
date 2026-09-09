* Ein Zeichenvergleich ordnet nach der EBCDIC-Sortierfolge, nicht nach
* der des Wirts. strcmp() ordnet nach den ASCII-Werten, die die
* Quellzeichen hier zufaellig haben, und die beiden Folgen weichen an
* genau EINER Stelle voneinander ab, die Assemblerquellen erreichen:
*
*     In EBCDIC sortieren BUCHSTABEN VOR ZIFFERN, in ASCII danach.
*
* Buchstabe gegen Buchstabe und Ziffer gegen Ziffer stimmen in beiden
* ueberein - deshalb waren C3 und C4 immer richtig, und deshalb sind
* fuenf Instrumente zwei Tage lang daran vorbeigelaufen (cc370#264).
*
* AMACLIB(DOM) prueft ein Register mit der ueblichen IBM-Wendung
*
*     AIF ('&MSG(1)' GE '1' AND '&MSG(1)' LE '12').DOML4
*
* und `DOM MSG=(R1)' macht daraus 'R1' LE '12' - in EBCDIC wahr, hier
* falsch. 103 Makros der Bibliotheken tragen diese Form.
*
* C3 und C4 sind die Kontrollen: sie stimmen in BEIDEN Sortierfolgen,
* eine Fixture nur daraus besteht auf beiden Binaries. C6 und C7
* halten die Laengenregel aus #189 fest, die vor dem Inhalt greift und
* sich nicht bewegen darf.
*
* Punktzahl:  ohne Fix N1 N2 Y3 Y4 N5 Y6 Y7
*             mit Fix  Y1 Y2 Y3 Y4 Y5 Y6 Y7
COLLATE  CSECT
         AIF   ('A' LE '1').A
         DC    C'N1'
         AGO   .B
.A       DC    C'Y1'
.B       AIF   ('Z' LT '0').C
         DC    C'N2'
         AGO   .D
.C       DC    C'Y2'
.D       AIF   ('A' LT 'B').E
         DC    C'N3'
         AGO   .F
.E       DC    C'Y3'
.F       AIF   ('1' LT '2').G
         DC    C'N4'
         AGO   .H
.G       DC    C'Y4'
.H       AIF   ('R1' LE '12').I
         DC    C'N5'
         AGO   .J
.I       DC    C'Y5'
.J       AIF   ('2' LE '11').K
         DC    C'N6'
         AGO   .L
.K       DC    C'Y6'
.L       AIF   ('B' LE 'AB').M
         DC    C'N7'
         AGO   .N
.M       DC    C'Y7'
.N       ANOP
         END
