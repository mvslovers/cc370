* Laenge eines SETC-Wertes (#151).
*
* as370 klemmt einen SETC-Wert bei 95 Zeichen; IFOX00 haelt 255
* (ifnx3a.asm:274 MAXCHAR, IFO105 darueber).  Alles zwischen 96
* und 255 geht still verloren.
*
* &T wird ueber drei Zuweisungen auf 128 Zeichen verkettet.  Dann
* zwei Teilzeichenketten, eine diesseits der Kappe und eine
* jenseits:
*
*   Regel A  Wert vollstaendig (255)
*              &X = AB   &Y = EF   K'&T = 128   ->  [AB][EF]
*   Regel B  Wert bei 95 geklemmt
*              &X = AB   &Y = leer, IFO117      ->  [AB][]
*
* Der Verlust meldet sich unter fremdem Namen: das IFO117 stimmt
* ueber den geklemmten Wert und luegt ueber das Programm.  Vor
* #141 war dieselbe Klemmung STILL und lieferte falsche Zeichen
* ins Deck.
*
* Eigener Code -- der Fund kam aus einem Makro, dessen Herkunft
* nicht feststeht, und haengt an dieser Fixture nicht.
T        CSECT
         LCLC  &T,&X,&Y
&T       SETC  '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'
&T       SETC  '&T.0123456789ABCDEF0123456789ABCDEF0123456789ABCD'
&T       SETC  '&T.EF0123456789ABCDEF0123456789ABCDEF'
&X       SETC  '&T'(59,2)
&Y       SETC  '&T'(127,2)
A        DC    C'[&X][&Y]'
         END
