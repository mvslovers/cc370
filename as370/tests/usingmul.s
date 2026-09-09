* Mehrere Basisregister in EINER USING (#154).
*
* `USING D,11,12,10' verteilt die Register NACH POSITION: 11 deckt
* D, 12 deckt D+4096, 10 deckt D+8192.  as370 las nur das erste
* Register und liess den Rest fallen -- alles jenseits der ersten
* 4096 Bytes war dann nicht adressierbar und wurde mit Basis 0 und
* Distanz 0 genullt, mit IFO209.
*
* Die Registerfolge ist ABSICHTLICH nicht aufsteigend.  Wer nach
* Registernummer statt nach Position verteilt, bekaeme fuer HIGH
* die 11 und fuer HIGH2 die 12 -- der Fehler faellt hier durch und
* nicht erst im Baum.
*
* EDGE trennt noch eine dritte Lesart ab: gaeben alle genannten
* Register DIESELBE Basis, dann deckte bei T+4092 jedes von ihnen
* den Operanden, und die Gleichstandsregel aus #138 naehme das
* hoechste (12).  Nur bei aufsteigenden Bereichen bleibt es die 11.
*
*   L 1,LOW    5810 B01C   erster Bereich -- Kontrolle
*   L 2,HIGH   5820 C000   zweiter Bereich
*   L 3,HIGH2  5830 A000   dritter Bereich
*   L 4,EDGE   5840 BFFC   letztes Byte des ersten Bereichs
*
* Die beiden letzten Faelle sind die Gegenprobe auf #177: die
* Schluesselung nach Basisregister muss ueber die Mehrfach-USING
* hinweg halten.
*
*   L 5,HIGH2  5850 9000   DROP 10 hat GENAU den dritten Eintrag
*                          geloescht; stuende er noch, gaebe die
*                          Gleichstandsregel die 10 statt der 9
*   L 6,LOW    5860 C01C   `USING T,12' ERSETZT den zweiten
*                          Eintrag; 11 und 12 liegen dann gleich
*                          auf, und das hoechste Register gewinnt
T        CSECT
         USING T,11,12,10
         L     1,LOW
         L     2,HIGH
         L     3,HIGH2
         L     4,EDGE
         DROP  10
         USING HIGH2,9
         L     5,HIGH2
         USING T,12
         L     6,LOW
         BR    14
LOW      DS    F
         ORG   T+4092
EDGE     DS    F
HIGH     DS    F
         ORG   T+8192
HIGH2    DS    F
         END   T
