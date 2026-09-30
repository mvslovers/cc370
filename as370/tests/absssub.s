* cc370#342: an SS operand written with a LENGTH subscript and no
* base, whose symbol is ABSOLUTE, under an ABSOLUTE USING.  The same
* symbol without a subscript already takes the USING (#190); with
* the length it came out with base 0.
*
* Predictions, written before the capture:
*   A1 XC  FLD(1),FLD       op1: length only        D700 2100 2100
*   A2 AP  FLD(2),FLD2(1)   two lengths, both       FA10 2100 212C
*   A3 MVC FLD(4),8(3)      op2 subscript = BASE 3  D203 2100 3008
*   A4 OI  8(4),X'01'       SI subscript = BASE 4   9601 4008
*   A5 CLC FLD(2),FLD2      op2 no subscript        D501 2100 212C
*   A6 XC  FLD(1),FLD       after DROP 2: base 0    D700 0100 0100
* A3 and A4 are the controls that failed a too-broad first attempt:
* there the subscript is an explicit base and must stay one.  The
* relocatable USING *,15 must never serve an absolute operand.
T        CSECT
         USING *,15
DUM      EQU   0
FLD      EQU   DUM+256
FLD2     EQU   DUM+300
         USING DUM,2
A1       XC    FLD(1),FLD
A2       AP    FLD(2),FLD2(1)
A3       MVC   FLD(4),8(3)
A4       OI    8(4),X'01'
A5       CLC   FLD(2),FLD2
         DROP  2
A6       XC    FLD(1),FLD
         END
