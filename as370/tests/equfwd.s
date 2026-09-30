* cc370#89: an EQU operand naming a symbol not defined YET. IFOX00
* resolves EQU in pass 1. The corpus has 8 sites in 3 modules;
* IKJEGMNL's six say IFO231 and its deck carries 0, but a second
* expansion redefines the names there (IFO196), so the corpus
* cannot say which rule set the value.
*
* Predictions, written before the oracle was asked:
*   FA  EQU FB         IFO231 FB, FA = 0 (not 4)
*   FC  EQU NEVER      IFO188 NEVER, FC = 0
*   FD  EQU LAB2-LAB1  IFO231 twice (LAB2, LAB1), FD = 0 (not 4)
*   FE  EQU LAB1       IFO231 LAB1, FE = 0; absolute or
*                      relocatable is the open question (RLD)
*   BK  EQU FB         silent, BK = 4 -- control
*   DUP EQU 1/DUP EQU 2  IFO196 on the second, DUP stays 1
* The DCs carry the values: A(FA) 0, A(FD) 0, A(FE) 0 or 0+RLD,
* A(BK) 4, A(DUP) 1 (keep-first) or 2 (keep-last), A(FC) 0.
T        CSECT
         DS    XL16
FA       EQU   FB
FB       EQU   4
FC       EQU   NEVER
FD       EQU   LAB2-LAB1
FE       EQU   LAB1
BK       EQU   FB
DUP      EQU   1
DUP      EQU   2
LAB1     DS    F
LAB2     DS    F
         DC    A(FA)
         DC    A(FD)
         DC    A(FE)
         DC    A(BK)
         DC    A(DUP)
         DC    A(FC)
         END
