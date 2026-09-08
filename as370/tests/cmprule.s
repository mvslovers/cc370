* Ein ZEICHENvergleich ordnet zuerst nach LAENGE (#153).
*
* Eine kuerzere Zeichenkette ist kleiner als eine laengere,
* gleich welche Zeichen darin stehen.  strcmp() liest dagegen von
* links und macht '2' groesser als '11' -- eine Schleife
*
*   AIF   ('&AA' LE '&DD').NEXT
*
* mit einem SETA-Zaehler endet dann nach dem ersten Durchlauf.
* Genau so baut IEECDCM seine Bildschirmtabellen: as370 erzeugte
* DCMMSG1 und hoerte auf, DCMMSG8 und DCMSEC9 blieben undefiniert.
*
* Die Buchstabenfaelle stehen daneben, weil Zahlen allein die
* Regel nicht festlegen: bei ihnen liefert "arithmetisch" dasselbe
* wie "nach Laenge", bei D und F nicht mehr.
*
*   A 2 LE 11    J      D B  LE AB   J
*   B 9 LE 10    J      E A  LE AB   J
*   C 10 LE 9    N      F AB LE B    N
*
* Und die Gegenprobe bei gleicher Laenge, wo der Inhalt zaehlt:
*
*   G AB LE AC   J      H AC LE AB   N
         MACRO
         TC    &X,&Y,&E
         AIF   ('&X' LE '&Y').JA
         DC    C'&E.N'
         MEXIT
.JA      ANOP
         DC    C'&E.J'
         MEND
T        CSECT
         TC    2,11,A
         TC    9,10,B
         TC    10,9,C
         TC    B,AB,D
         TC    A,AB,E
         TC    AB,B,F
         TC    AB,AC,G
         TC    AC,AB,H
         END   T
