* cc370#364: a USING whose base operand is a PARENTHESISED expression.
*
* IGARPT01 writes `USING (IGARPT01+X'4B0'),R15' -- a GODOWNTO entry
* point at a fixed offset into the module -- and as370 valued that
* base at 0. expr_val reads a LEADING '(' as a machine-operand
* subscript and returns without evaluating anything, so every
* displacement taken through R15 came out exactly the USING constant
* too high. 94 bytes over 47 halfwords, and both assemblers silent:
* the one module in SYS1.LPALIB where as370 disagrees with IFOX00.
*
* The fixture is self-proving. Cases 1 and 2 are the SAME expression,
* once parenthesised and once not, so the two instructions must
* assemble to identical bytes by the definition of a parenthesis. A
* wrong answer is visible without asking the oracle, and the
* invariant cannot go stale the way a written-down displacement can.
*
* Predictions, before the oracle was asked:
*   1  L 1,FIELD under USING (T+X'10'),2   base 2, disp FIELD-X'10'
*   2  L 1,FIELD under USING T+X'10',2     identical bytes to 1
*   3  L 1,FIELD under USING T+(X'8'+X'8'),2  identical bytes to 1
*
* Case 3 is the boundary: an INNER parenthesis was always evaluated
* (x_factor has a group branch), only a leading one was not, so it
* passes on both binaries and says where the defect stops.
*
* The DSECT domain on R12 is the second control, and it is for the
* SECTION the domain is filed under rather than for the base value.
* The base symbol is extracted by scanning to the first delimiter
* and '(' is one, so a parenthesised operand names no symbol at all
* and the domain is attributed to whatever sym_find("") answers. If
* that is not this section, using_for loses its same-section
* preference for FIELD and the operand resolves through R12 -- a
* wrong base REGISTER, which case 2 would then not match either.
*
* Pre-fix (4ca0353) case 1 is 5810 2050 where case 2 is 5810 2040,
* and the DSECT control does NOT fire here: this module has no
* unnamed private-code section, so sym_find("") answers nothing and
* the domain still lands in T. The module that makes the section
* half visible is tests/usingparenpc.s.
D        DSECT
DFLD     DS    F
T        CSECT
         USING D,12
         USING (T+X'10'),2
         L     1,FIELD
         DROP  2
         USING T+X'10',2
         L     1,FIELD
         DROP  2
         USING T+(X'8'+X'8'),2
         L     1,FIELD
         DROP  2
         BR    14
         DS    16F
FIELD    DS    F
         END   T
