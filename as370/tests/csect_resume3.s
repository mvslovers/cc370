* Fortsetzung MAL END-Literalpool -- die Komposition, nicht die Teile.
*
* Der END-Pool gehoert dem ERSTEN Abschnitt (#68) und wird dort an
* dessen Ende abgelegt.  Er verlaengert also A, nachdem B laengst
* eroeffnet ist.  Wenn Origins aus den ENDlaengen kommen, muss B hinter
* dem Pool liegen, nicht davor:
*
*   B ADDR 000010 -> der Pool zaehlt zu A's Endlaenge, B rueckt nach
*   B ADDR 000008 -> B steht vor dem Pool, die Verkettung ignoriert ihn
A        CSECT
         USING *,15
         L     1,=F'1'
B        CSECT
         DC    C'BBBBBBBB'
A        CSECT
         DC    C'aa'
         END
