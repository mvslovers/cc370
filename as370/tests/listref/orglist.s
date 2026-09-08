* Jede Anweisung, die den Ortszaehler VERSCHIEBT oder ERSETZT, listete
* bei as370 den Wert, den er beim Eintritt hatte - lrecs[].loc wird
* gestempelt, bevor die Anweisung laeuft (cc370#227). Fuer eine
* Instruktion oder ein DC ist das genau richtig; fuer diese hier nicht.
*
* ORG:    IFOX00 behaelt in LOC den Zaehler VORHER und setzt den neuen
*         in ADDR2. Alle drei Formen stehen hier: ORG *-4, blankes ORG
*         (Hochwassermarke) und ORG PD+20 - dazu eines in einer DSECT.
* CSECT:  der eigene Zaehler des Abschnitts. PDB ist neu (000018, sein
*         Ursprung), PD danach FORTGESETZT (000015, wo es aufhoerte) -
*         ohne den fortgesetzten Fall waeren "Ursprung" und "eigener
*         Zaehler" nicht zu unterscheiden.
* DSECT:  von null bei der ersten Oeffnung, fortgesetzt danach.
*
* CM1 weicht bewusst ab und der Pruefer BEHAUPTET das: as370 kennt COM
* nicht - kein ESD-Eintrag, kein Zaehler ab null (cc370#229). Wird das
* behoben, faellt dieser Fall auf und verlangt die Anpassung. Auch die
* drei Karten danach haengen daran.
PD       CSECT
P1       DS    CL10
         ORG   *-4
P2       DS    CL2
         ORG
P3       DS    CL2
         ORG   PD+20
P4       DS    CL1
PDB      CSECT
Q1       DS    CL6
PD       CSECT
P5       DS    CL1
DM1      DSECT
R1       DS    CL4
         ORG   *-2
R2       DS    CL2
DM1      DSECT
R3       DS    CL3
CM1      COM
S1       DS    CL5
PD       CSECT
         LTORG
         END
