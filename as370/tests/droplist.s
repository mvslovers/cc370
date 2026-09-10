* cc370 -- a DROP names as many registers as it likes.  The
* operand list was cut at four, so IGC0001F's eight-register
* DROP left the last four registered, and a later USING on the
* same section tied against a base that should have been gone.
*
* Every register dropped below has an active USING first, which
* is the shape IGC0001F has and which IFOX00 accepts.
* Control inside the fixture: the first L uses a four-register
* DROP, which already worked.  Both L must show base 9.
DROPL    CSECT
R1       EQU   1
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R12      EQU   12
R15      EQU   15
         USING MYD,R15
         USING MYD,R5
         USING MYD,R12
         USING MYD,R8
         DROP  R15,R5,R12,R8
         USING MYD,R9
         L     1,FLD
         DROP  R9
         USING MYD,R1
         USING MYD,R5
         USING MYD,R6
         USING MYD,R7
         USING MYD,R8
         USING MYD,R12
         USING MYD,R15
         DROP  R1,R5,R6,R7,R8,R12,R15
         USING MYD,R9
         L     2,FLD
MYD      DSECT
         DS    CL8
FLD      DS    F
         END
