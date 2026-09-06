* Typattribut eines selbstdefinierten Terms (#142).
*
* T' eines selbstdefinierten Terms ist 'N', unabhaengig von der
* Schreibweise.  Gemessen gegen IFOX00, alle acht Faelle:
*
*   X'C0D'  N     4095    N     B'1010'  N     C'AB'  N
*   C'&&'   N     C''''   N     -1       U     NOSUCH U
*
* Zwei Grenzen, beide gegen die Intuition und beide gemessen:
*
*   - ein VORZEICHENBEHAFTETES Dezimalliteral ist KEIN selbst-
*     definierter Term.  -1 ist 'U'.  Der alte Alle-Ziffern-Test
*     traf das zufaellig richtig, aus dem falschen Grund.
*   - C'&&' und C'''' SIND selbstdefinierte Terme.  Der doppelte
*     Ampersand und das doppelte Hochkomma sind je ein Zeichen,
*     der Lauf zwischen den Begrenzern wird nicht inspiziert.
*
* as370 antwortete 'N' nur bei lauter Dezimalziffern, also fielen
* die X/B/C-Formen auf 'U' und jedes Makro mit
*   AIF (T'&X NE 'N')
* nahm den falschen Zweig -- stumm, bei rc=0.  225 Makros im Baum
* verzweigen auf ein Typattribut; SYS1.AMACLIB(ABEND) machte
* ABEND X'C0D',,,SYSTEM zu 24 statt 10 Byte.
*
* Ein definiertes SYMBOL antwortet mit seinem DS/DC-Typbuchstaben
* (F/H/C/X), was as370 nicht je Symbol vorhaelt -- eigenes Issue.
         MACRO
         SHOWT &CC
         AIF   (T'&CC NE 'N').OTHER
         DC    C'N'
         MEXIT
.OTHER   ANOP
         DC    C'U'
         MEND
T        CSECT
         SHOWT X'C0D'
         SHOWT 4095
         SHOWT B'1010'
         SHOWT C'AB'
         SHOWT C'&&'
         SHOWT C''''
         SHOWT -1
         SHOWT NOSUCH
         END
