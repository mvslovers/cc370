* T' woertlich geschrieben, nicht ueber eine Variable (#146).
*
* tattr_symbol.s prueft nur T'&CC -- das Symbol kommt dort durch
* einen Makroparameter.  Ein woertliches T'SF nahm einen anderen
* Zweig und lieferte 'O' (weggelassener Operand), weil die Auswertung
* nur die Variablenform kannte.  Beide Formen gehoeren geprueft; die
* Luecke lag genau zwischen den beiden Fixtures.
*
* Gemessen gegen IFOX00: alle fuenf Faelle OK, offener Code wie
* Makrorumpf, woertlich wie ueber Parameter.
*
* NICHT geprueft wird hier "AIF (T'X'C0D' ...)" in OFFENEM Code: das
* ist unzulaessig, IFOX stellt IFO036 ATTRIBUTE REFERENCE FOR T'X'C0D'
* IS INVALID und nimmt den falschen Zweig.  as370 akzeptiert es und
* antwortet 'N' -- eine fehlende Diagnose, kein Gewinn.  Ueber einen
* Makroparameter ist dieselbe Konstante zulaessig und ergibt 'N'.
         MACRO
         VIA   &CC,&EXP
         AIF   (T'&CC EQ '&EXP').OK
         DC    C'BAD'
         MEXIT
.OK      ANOP
         DC    C'OK '
         MEND
T        CSECT
SF       DS    F
SC       DS    CL3
* -- woertlich, offener Code
         AIF   (T'SF EQ 'F').L1
         DC    C'BAD'
         AGO   .D1
.L1      ANOP
         DC    C'OK '
.D1      ANOP
         AIF   (T'SC EQ 'C').L2
         DC    C'BAD'
         AGO   .D2
.L2      ANOP
         DC    C'OK '
.D2      ANOP
* -- ueber einen Parameter, Makrorumpf
         VIA   SF,F
         VIA   SC,C
         VIA   X'C0D',N
         END
