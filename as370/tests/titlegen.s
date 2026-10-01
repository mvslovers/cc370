* TITLE unter PRINT NOGEN, SPACE und EJECT (#603).
*
* titlepage.s zeigt: ein TITLE aus einer Expansion unter PRINT
* NOGEN beginnt keine Seite. Offen ist, ob er den Titel trotzdem
* setzt -- das zeigt der Kopf der Ueberlaufseite am Ende: N1 OFFEN
* oder N2-NOGEN. Dazu SPACE 2 und ein EJECT mitten auf der Seite.
         MACRO
         TMAC  &T
         TITLE '&T'
         DC    C'M'
         MEND
TGEN     CSECT
         TITLE 'N1 OFFEN'
         DC    C'A1'
         PRINT NOGEN
         TMAC  N2-NOGEN
         PRINT GEN
         DC    C'A2'
         SPACE 2
         DC    C'A3'
         EJECT
         DC    C'A4'
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
         END
