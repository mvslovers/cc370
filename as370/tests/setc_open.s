* SETC-Substitution in OFFENEM Code, und die Teilzeichenkette.
*
* Gemessen gegen IFOX00:
*   DC    C'[&A][&B]'   ->  BABBBAC2C3C4BB   = [][BCD]
*   Anweisung 3         ->  IFO117 FIRST EXPRESSION IN SUBSTRING
*                           NOTATION EXCEEDS THE LENGTH OF THE STRING
*
* Zwei getrennte Befunde in einem Fall:
*
*   1. IFOX substituiert &A und &B im DC-Operanden.  as370 gab
*      BA50C1BB BA50C2BB aus -- den Variablennamen woertlich als
*      Daten.  Im Makrorumpf substituiert as370 (&SYSECT laeuft),
*      in offenem Code nicht.
*   2. 'AB'(5,4) greift ueber das Ende.  IFOX liefert die leere
*      Zeichenkette UND stellt IFO117; as370 nahm es wortlos an.
*
* Der zweite Befund ist der Ausloeser in IEDQE2, wo IEDHJN
* '&SYSPARM'(1,4) auf ein leeres &SYSPARM anwendet.
T        CSECT
         LCLC  &A,&B
&A       SETC  'AB'(5,4)
&B       SETC  'ABCDEF'(2,3)
         DC    C'[&A][&B]'
         END
