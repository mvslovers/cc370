* CNOP richtet auf ein HALBWORT aus, bevor es irgendetwas anderes tut:
* ein ungerader Ortszaehler wird mit EINEM Nullbyte hochgezogen. Die
* Marke adressiert GENAU DIESE Stelle - vor den No-ops (cc370#231).
*
* as370 zaehlte stattdessen in Zweierschritten von dort weiter, wo es
* gerade stand, und gab nach 64 Versuchen auf. Von einem ungeraden
* Zaehler aus konnte es einen geraden Rest nie erreichen: 64 No-ops,
* der Zaehler 128 Bytes weiter, stillschweigend bei rc 0 - und jede
* folgende Adresse im Abschnitt falsch. `N1 CNOP 0,4' ein Byte hinter
* dem Abschnittsanfang legte die naechste Anweisung auf x'81', wo
* IFOX00 x'04' hat.
*
* Und die Marke wurde ueberhaupt nie definiert. Jedes Makro, das mit
* `&NAME CNOP 0,4' ausrichtet - LOAD, LINK, CALL und Verwandte -
* verlor damit das Symbol aus dem Namensfeld des Aufrufers.
*
* Die A-Konstanten sind der Beweis fuer die Lage der Marke: N1 muss 2
* sein. 1 waere vor der Halbwortausrichtung, 4 dahinter nach den
* No-ops - beide falschen Regeln fallen hier auf.
*
* N2 und N6 sind die Kontrollen: der Rest stimmt schon, es darf KEIN
* No-op entstehen. Ein Fix, der immer eines schreibt, faellt dort auf.
* N3 und N4 pruefen ein anderes Vielfaches und einen Rest ungleich 0.
*
* Punktzahl:  ohne Fix N1/N2 undefiniert, Abschnitt ab x'81' zerstoert
PG       CSECT
         DC    C'A'
N1       CNOP  0,4
         DC    A(N1)
         DC    C'B'
N2       CNOP  2,4
         DC    A(N2)
         DC    C'C'
N3       CNOP  0,8
         DC    A(N3)
         DC    C'D'
N4       CNOP  4,8
         DC    A(N4)
         DC    C'EF'
N5       CNOP  0,4
         DC    A(N5)
N6       CNOP  0,4
         DC    A(N6)
         END
