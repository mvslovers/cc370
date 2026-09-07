* Ein Variablensymbol im OPERATIONSFELD in offenem Code (#141).
*
* IFOX substituiert das Operationsfeld VOR dem Nachschlagen
* (ifnx3a.asm:576 vor OPSC1:622).  Zwei Fragen:
*
* 1. A -- eine Anweisung als Wert
*      substituiert    A DC C'X'  ->  E7
*      nicht           IFO101, oder gar nichts
* 2. B -- ein MAKRONAME als Wert
*      Makroaufrufe sind in der Editierphase schon aufgeloest
*                      IFO101, KEINE Expansion
*      oder doch       Expansion, DC C'MAC'
*    Entscheidet, ob msub vor mac_find/lib_load laufen darf oder
*    nur vor known_op.
         MACRO
         MYMAC
         DC    C'MAC'
         MEND
T        CSECT
         LCLC  &O,&P
&O       SETC  'DC'
&P       SETC  'MYMAC'
A        &O    C'X'
B        &P
C        DC    C'END'
         END
