* cc370#362 / #26: an operand that is not SIMPLY RELOCATABLE. IFOX00
* answers IFO217 RELOCATABILITY ERROR NEAR OPERAND COLUMN n at
* severity 12; as370 has no such check and assembles something.
*
* Predictions, written down before the oracle was asked, and one of
* the three was WRONG:
*   predicted  both flagged statements produce IFO217
*   measured   they produce DIFFERENT messages -- IFO217 for the
*              multiply, IFO213 COMPLEXLY RELOCATABLE EXPRESSION for
*              the two unpaired terms. One check, two diagnostics.
*   predicted  IFOX00 zeroes the instruction, four bytes 00000000
*   measured   correct, both statements
*   predicted  rc 12
*   measured   correct, 2 statements flagged, highest severity 12
* The fixture caught that only because it carries two DIFFERENT bad
* expressions. With one shape it would have confirmed the wrong half
* of the prediction and hidden IFO213 entirely.
*
* IFO213 OCCURS NOWHERE IN THE CORPUS -- 0 of 926 diagnostic files,
* against IFO217 at 75 and IFO188 at 282 as instrument controls. So
* for IFO213 this fixture is not the first check, it is the ONLY one
* that will ever exist here, and the tree gate cannot see a wrong
* message at all. Hence two more shapes rather than one construction:
*   FLDX-OTHER  predicted IFO213 -- a pair that does not cancel
*               because the two symbols are in different sections
*   0-FLDX      predicted IFO213 -- a single unpaired NEGATIVE term
* Both zeroed, per the measured behaviour of the other two.
*
* Oracle: MVSTK5-REF, JOB00034, 2026-09-11.
*   The two controls assemble normally, which is what proves the
*   fixture tests relocatability rather than a parse failure.
*
* as370 today, on a1b101d, flags NOTHING and emits 5810 0000 for the
* first: base 0, displacement 0, at rc 0. That is the #26 half.
*
* The two mechanisms #26 names, one card each:
*   FLDX*2-FLDX   relocatability lost across a multiply
*   (B-A)         a paren subterm spanning two control sections
T        CSECT
         USING T,12
FLDX     DS    F
FLDY     DS    F
         L     2,FLDY-FLDX        control: absolute difference, legal
         L     3,FLDX             control: simply relocatable, legal
         L     1,FLDX*2-FLDX      relocatable across a multiply
         L     4,FLDX+FLDY        two unpaired relocatable terms
         L     5,FLDX-OTHER       paired across two control sections
         L     6,0-FLDX           one term, unpaired and negative
OTHER    CSECT
OFLD     DS    F
         END
