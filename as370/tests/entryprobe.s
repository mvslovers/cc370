* cc370#559 and three questions left open by #89/#556. Every case
* has its own names so no answer leaks into another.
*
* Predictions, written before the oracle was asked:
*  ENTRY (#559) -- IFOX00 writes an LD only for a relocatable name
*   E1 label, defined after the ENTRY      LD, silent    control
*   E2 label, defined before the ENTRY     LD, silent    control
*   E3 absolute EQU, defined after         IFO189, no LD
*   E4 absolute EQU, defined before        IFO189, no LD
*   E5 EQU of a label (relocatable)        LD, silent
*   E6 never defined                       IFO188 or IFO189, no LD
*   E7 forward EQU of a label (IKJEGMNL)   IFO231 + IFO189, no LD
*  X2 EQU FWD2-FWD2, FWD2 defined later    IFO231 TWICE, X2 = 0
*  EXTRN XE, then XE DS F                  IFO196 on the DS; XE
*                                          stays an ER: A(XE) = 0
*                                          with an RLD against it
*  ORG *+FWDO, FWDO EQU 8 later            IFO231, counter does not
*                                          move: AFTER = BEFORE
T        CSECT
         ENTRY E1,E2,E3,E4,E5,E6,E7
         EXTRN XE
E2       DS    F
E4       EQU   5
E1       DS    F
E3       EQU   6
E5       EQU   E1
E7       EQU   LATER
X2       EQU   FWD2-FWD2
XE       DS    F
LATER    DS    F
FWD2     DS    F
         DC    A(E3)
         DC    A(E7)
         DC    A(X2)
         DC    A(XE)
BEFORE   DS    0F
         ORG   *+FWDO
AFTER    DS    0F
FWDO     EQU   8
         DC    A(AFTER-BEFORE)
         END
