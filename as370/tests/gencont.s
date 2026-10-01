* Fortgesetzte Modellanweisungen im Listing (#370).
* IFOX00 setzt in den logischen Text ein (Karte 1 Spalte 1-71, jede
* Fortsetzung ab Spalte 16) und schneidet das Ergebnis neu in Karten.
*   CPLN  nichts ersetzt, zwei Karten     CORD  ersetzt, wird kuerzer
*   CSPL  Fortsetzung schneidet &A(2)     CGRO  ersetzt, wird laenger
*   C3    drei Karten, nichts ersetzt     CSEQ  Folgenummern auf beiden
         MACRO
         CPLN
         DC    C'PLAIN.ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZX
               ZZZ'
         MEND
         MACRO
         CORD
         LCLC  &A(2)
&A(1)    SETC  'XX'
&A(2)    SETC  'YY'
         DC    C'&A(1).&A(2).ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZX
               ZZZ'
         MEND
         MACRO
         CSPL
         LCLC  &A(2)
&A(1)    SETC  'XX'
&A(2)    SETC  'YY'
         DC    C'&A(1).ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ&AX
               (2)'
         MEND
         MACRO
         CGRO
         LCLC  &L
&L       SETC  'LLLLLLLLLLLLLLLLLLLL'
         DC    C'&L.GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGX
               GGG'
         MEND
         MACRO
         C3
         DC    C'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTX
               UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUX
               VVV'
         MEND
         MACRO
         CSEQ
         DC    C'SEQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQX00010001
               QQQ'                                                     00010002
         MEND
TGC      CSECT
         CPLN
         CORD
         CSPL
         CGRO
         C3
         CSEQ
         END
