* TITLE und der Seitenkopf (#603).
*
* Was IFOX00 an TK5-Listings schon zeigt (mvs38src ifox-run):
* jeder TITLE beginnt eine Seite, sein Text steht ab Spalte 10
* im Kopf jeder SOURCE-Seite bis zum naechsten TITLE, die Anweisung
* wird gezaehlt, aber nicht gelistet; ein TITLE aus einer
* Makroexpansion tut dasselbe. Offen, und hier gemessen:
*   Q1  Kopf der ersten Seite vor jedem TITLE (leer?)
*   Q2  '' und && im Operanden: einfach oder doppelt im Kopf
*   Q3  EJECT direkt nach TITLE: eine leere Seite oder keine
*   Q5  Seitenueberlauf: traegt die Folgeseite den Titel
*   Q6  TITLE im Makro unter PRINT GEN und unter PRINT NOGEN
         MACRO
&L       TMAC  &T
         TITLE '&T'
&L       DC    C'M'
         MEND
TPAGE    CSECT
         DC    C'P1'
         TITLE 'Q2 A''B&&C'
         DC    C'Q2'
         TITLE 'Q3 EJECT FOLGT'
         EJECT
         DC    C'Q3'
         TITLE 'Q5 UEBERLAUF'
         DC    C'00'
         DC    C'01'
         DC    C'02'
         DC    C'03'
         DC    C'04'
         DC    C'05'
         DC    C'06'
         DC    C'07'
         DC    C'08'
         DC    C'09'
         DC    C'10'
         DC    C'11'
         DC    C'12'
         DC    C'13'
         DC    C'14'
         DC    C'15'
         DC    C'16'
         DC    C'17'
         DC    C'18'
         DC    C'19'
         DC    C'20'
         DC    C'21'
         DC    C'22'
         DC    C'23'
         DC    C'24'
         DC    C'25'
         DC    C'26'
         DC    C'27'
         DC    C'28'
         DC    C'29'
         DC    C'30'
         DC    C'31'
         DC    C'32'
         DC    C'33'
         DC    C'34'
         DC    C'35'
         DC    C'36'
         DC    C'37'
         DC    C'38'
         DC    C'39'
         DC    C'40'
         DC    C'41'
         DC    C'42'
         DC    C'43'
         DC    C'44'
         DC    C'45'
         DC    C'46'
         DC    C'47'
         DC    C'48'
         DC    C'49'
         DC    C'50'
         DC    C'51'
         DC    C'52'
         DC    C'53'
         DC    C'54'
         DC    C'55'
         DC    C'56'
         DC    C'57'
         DC    C'58'
         DC    C'59'
         TITLE 'Q6 VOR DEM AUFRUF'
         DC    C'G0'
G1       TMAC  Q6-GEN
         DC    C'G1'
         PRINT NOGEN
G2       TMAC  Q6-NOGEN
         PRINT GEN
         DC    C'G2'
         END
