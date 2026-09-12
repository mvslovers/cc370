* cc370#366: the order of RLD entries within one (R,P) group.
*
* IFFAHA16 builds a 256-word branch table indexed by EBCDIC
* character code, and it fills the slots with `ORG ADDR+C'x'*4'
* followed by `DC A(CODEnn)'. The location counter therefore walks
* the table in CHARACTER order, not in address order, and as370
* recorded the relocations in the order it met them. IFOX00 emits
* them in ascending ADDRESS order within each (R,P) group.
*
* Same relocations, same flags, same object image -- only the RLD
* cards differ, which is why nothing that rebuilds the image can
* see it. Measured over the recorded corpus: of 3,021 IFOX00 decks
* carrying relocations, 3,021 ascend by address within each group
* and none does otherwise. Of as370's, exactly one did not, and it
* is IFFAHA16.
*
* Predictions, before the oracle was asked:
*   1  the four A-cons emit RLD entries at 000,004,008,00C
*      in that order, whatever order the ORGs wrote them
*   2  the two V-cons do the same at 010,014 -- the V path shares
*      the table, so a fix that sorts only A-cons fails here
*   3  the two groups stay in the order as370 already writes them:
*      the section's own (R=P=1) group first, the ER's after it.
*      Grouping is not what changes; only the order within a group
*
* Case 3 is the control. The sort gains a third key and keeps the
* first two, so a fix that sorted globally by address would merge
* the two groups and fail here while passing 1 and 2.
*
* Pre-fix (e53f404) the A-con entries come out 00C,004,008,000 and
* the V-cons 014,010 -- emission order, and both groups otherwise
* correct.
T        CSECT
TAB      DS    4F
         ORG   TAB+12
         DC    A(C4)
         ORG   TAB+4
         DC    A(C2)
         ORG   TAB+8
         DC    A(C3)
         ORG   TAB
         DC    A(C1)
         ORG
VTAB     DS    2F
         ORG   VTAB+4
         DC    V(EXT)
         ORG   VTAB
         DC    V(EXT)
         ORG
C1       DS    F
C2       DS    F
C3       DS    F
C4       DS    F
         BR    14
         END   T
