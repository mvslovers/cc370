* '&SYSPARM'(1,4) auf einem leeren &SYSPARM (#141).
*
* Der namentliche Ausloeser des Issues, als eigener Code
* nachgebaut nach dem Muster des echten Makros: LCLC, dann zwei
* Teilzeichenketten auf &SYSPARM.  Ohne PARM=SYSPARM(...) ist das
* die leere Zeichenkette, und beide greifen ueber das Ende.
*
* Zwei Fragen in einer Fixture:
*
* 1. Ist &SYSPARM in OFFENEM Code definiert?
*      definiert, leer   (1,4) -> IFO117
*      undefiniert       IFO006 statt IFO117
* 2. Meldet IFOX die Teilzeichenkette auch im MAKRORUMPF?
*      ja    die Anweisungen im Rumpf werden geflaggt
*      nein  nur die offene
*    Entscheidet, ob die Diagnose in eval_setc gehoert -- also in
*    BEIDE Pfade -- oder nur in den Offen-Code-Pfad.
*
* 420 MVSBLD-Module haengen an Frage 2: sie rufen das Makro, und
* as370 hielt sie fuer sauber, weil es die Meldung nicht stellte.
         MACRO
         MHJN
         LCLC  &HJA,&HJB
&HJA     SETC  '&SYSPARM'(1,4)
&HJB     SETC  '&SYSPARM'(5,4)
M        DC    C'[&HJA][&HJB]'
         MEND
T        CSECT
         LCLC  &A
&A       SETC  '&SYSPARM'(1,4)
O        DC    C'[&A]'
         MHJN
         END
