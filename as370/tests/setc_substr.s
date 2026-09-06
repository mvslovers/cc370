* Grenzen der Teilzeichenkette in SETC (#141).
*
* Sechs Faelle, und was die Kandidatenregeln vorhersagen:
*
*   &A  'ABCDEF'(2,3)  gewoehnlich
*         beide Regeln         BCD, keine Meldung
*   &B  'AB'(3,1)       expr1 = Laenge+1
*         XF  (len < expr1)    leer, IFO117 sev 8, RC 8
*         HLASM                leer, keine Meldung, RC 0
*   &C  'AB'(2,9)       expr2 ueber das Ende hinaus
*         toter STR30          B, keine Meldung, RC 0
*         Warnung              B, sev 4, RC 4
*   &D  'AB'(0,2)       expr1 = 0
*         IFO115               leer, sev 8, RC 8
*         as370 heute          klemmt auf 1, liefert AB, still
*   &E  'AB'(-1,2)      expr1 < 0        wie &D
*   &F  'AB'(1,-1)      expr2 < 0
*         IFO116               leer, sev 4, RC 4
*         oder sev 8           leer, RC 8
*
* &D und &E trennen die Regeln in den BYTES, nicht nur im RC.
T        CSECT
         LCLC  &A,&B,&C,&D,&E,&F
&A       SETC  'ABCDEF'(2,3)
&B       SETC  'AB'(3,1)
&C       SETC  'AB'(2,9)
&D       SETC  'AB'(0,2)
&E       SETC  'AB'(-1,2)
&F       SETC  'AB'(1,-1)
         DC    C'[&A][&B][&C][&D][&E][&F]'
         END
