* Der erste Index eines SS-Operanden 1 ist die LAENGE (#203).
*
* Das Format ist D1(L1,B1), also steht in sub[0] die Laenge und
* nie eine Basis.  Der Rueckfall auf sub[0] reichte sie als
* Basisregister an die Maschine weiter: `CLC FLCPICOD(2),X' kam
* mit B1=2 heraus, wo IFOX00 B1=0 schreibt -- es adressierte
* R2+0x8E statt absolut 0x8E, und das ist in AHL* und AMD* der
* tiefe Speicher.  Dasselbe gilt fuer Operand 2 eines SS mit ZWEI
* Laengen, wo der einzige Index ebenfalls eine Laenge ist.
*
* sub[0] ist ueberladen, und es unterscheidet `ns', nicht der
* Wert: ohne geschriebene Klammerliste legt resolve() dort die
* aus einer USING gewaehlte Basis ab.  Den Rueckfall ganz zu
* streichen verliert die -- `CLC B(2),B' fiel von B1=12 auf 0,
* und die Suite sagte das im ersten Lauf.
*
*   main 4907207   D501208E D501508E D501C000 F922C004 F922308E
*   IFOX00, dies   D501008E D501508E D501C000 F922C004 F922008E
T        CSECT
         USING T,12
LOW      EQU   142               absolute Adresse im tiefen Speicher
B        DS    CL4
P        DS    PL3
         CLC   LOW(2),B          Laenge explizit, keine Basis
         CLC   LOW(2,5),B        Laenge und Basis explizit
         CLC   B(2),B            keine Liste: Basis aus USING
         CP    P(3),P(3)         zwei Laengen, relokierbar
         CP    LOW(3),LOW(3)     zwei Laengen, absolut
         BR    14
         END   T
