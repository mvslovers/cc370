* cc370#538 -- the cross-reference cases tests/listref does not reach.
* Captured with XREF(FULL) and again with XREF(SHORT).
* 
* 1  sixteen references to F1 in two statements: the 16th goes on a
*    continuation line, column 32
* 2  L'F1 in a machine operand is a reference
* 3  CNOP, CCW, USING and DROP operands; SPACE and MNOTE with a symbol
* 4  S and Y constants, a symbolic duplication factor and length
* 5  DUPE defined twice; XDEF declared EXTRN after it is defined
* 6  VONLY seen only in V(), then used in A()
* 7  an undefined name, and ENTRY of a defined one
* 8  literals of 130 and 122 characters: the text alone on a line,
*    then the rest from column 6 -- a rest of 2 stays on the LEN line
* 9  sixty more symbols, so the FULL listing runs past one page
* 10 an LTORG pool in a second section, and an END pool that goes
*    back into the first: listed in that order, cross-referenced
*    by address
XREFCOV  CSECT 
         USING XREFCOV,15
R1       EQU   1
ZERO     EQU   0
ONE      EQU   1
TWO      EQU   2
FOUR     EQU   4
CMD      EQU   X'02'
         DC    A(F1,F1,F1,F1,F1,F1,F1,F1) case 1
         DC    A(F1,F1,F1,F1,F1,F1,F1,F1)
         LA    R1,L'F1 case 2
         CNOP  TWO,FOUR case 3
         CCW   CMD,F1,ZERO,ONE
         SPACE ONE
         MNOTE ZERO,'XREFCOV'
         USING F1,R1
         DROP  R1
         DC    S(F1) case 4
         DC    Y(F1)
         DS    (TWO)FL(FOUR)
DUPE     EQU   5 case 5
DUPE     EQU   6
XDEF     DS    F
         EXTRN XDEF
         DC    V(VONLY) case 6
         DC    A(VONLY)
         DC    A(NOWHERE) case 7
         ENTRY F1
         LA    R1,=C'ABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJX
               ABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFX
               GHIJABCDEFGHIJABCDEF'
         LA    R1,=C'01234567890123456789012345678901234567890123456789X
               01234567890123456789012345678901234567890123456789012345X
               678901234567'
F1       DS    F
S01      DS    X
S02      DS    X
S03      DS    X
S04      DS    X
S05      DS    X
S06      DS    X
S07      DS    X
S08      DS    X
S09      DS    X
S10      DS    X
S11      DS    X
S12      DS    X
S13      DS    X
S14      DS    X
S15      DS    X
S16      DS    X
S17      DS    X
S18      DS    X
S19      DS    X
S20      DS    X
S21      DS    X
S22      DS    X
S23      DS    X
S24      DS    X
S25      DS    X
S26      DS    X
S27      DS    X
S28      DS    X
S29      DS    X
S30      DS    X
S31      DS    X
S32      DS    X
S33      DS    X
S34      DS    X
S35      DS    X
S36      DS    X
S37      DS    X
S38      DS    X
S39      DS    X
S40      DS    X
S41      DS    X
S42      DS    X
S43      DS    X
S44      DS    X
S45      DS    X
S46      DS    X
S47      DS    X
S48      DS    X
S49      DS    X
S50      DS    X
S51      DS    X
S52      DS    X
S53      DS    X
S54      DS    X
S55      DS    X
S56      DS    X
S57      DS    X
S58      DS    X
S59      DS    X
S60      DS    X
XREFB    CSECT  case 10
         USING XREFB,15
         LA    R1,=F'2'
         LTORG 
         USING XREFCOV,14
         LA    R1,=F'3'
         END   XREFCOV
