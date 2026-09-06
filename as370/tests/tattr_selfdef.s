* Typattribut eines selbstdefinierten Terms als Makroparameter.
*
* T' eines selbstdefinierten Terms ist 'N', unabhaengig von der
* Schreibweise.  Gemessen gegen IFOX00: X'C0D' und 4095 liefern
* beide [NUMERIC].  as370 lieferte fuer die hexadezimale Form
* [OTHER] und traf damit den falschen AIF-Zweig.
*
* Der Fall ist nicht akademisch.  SYS1.AMACLIB(ABEND) verzweigt
* auf genau diesem Test:
*
*     AIF   (T'&CC NE 'N').AA
*
* so dass "ABEND X'C0D',,,SYSTEM" bei as370 zu 24 Byte expandiert
* (B *+8 / DC AL4 / L / SLL / SRL / SVC) und bei IFOX zu 8.  In
* IEAVDSEG ist das die gesamte Laengendifferenz des Abschnitts,
* 340 gegen 324 Byte.
         MACRO
         SHOWT &CC
         DC    C'T=&SYSNDX.'
         AIF   (T'&CC NE 'N').OTHER
         DC    C'[NUMERIC]'
         MEXIT
.OTHER   ANOP
         DC    C'[OTHER]'
         MEND
T        CSECT
         SHOWT X'C0D'
         SHOWT 4095
         END
