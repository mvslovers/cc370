* cc370#364, the other half of the same statement: which SECTION a
* parenthesised USING domain is filed under.
*
* The base expression's leading symbol decides that, and the scan
* that finds it stops at the first delimiter -- of which '(' is one.
* So `USING (T+X'10'),2' named NOTHING, and "" is not a name: it is
* the unnamed private-code section, which sym_get("") enters in
* do_pass. In a module that HAS one, the domain was therefore filed
* under the private code, using_for lost its same-section preference
* for an operand in T, and the operand assembled with no base at all.
*
* Two cards of private code before the first CSECT are what make the
* blank name resolve; without them sym_find("") answers nothing and
* the misfiling is invisible -- which is why tests/usingparen.s, the
* IGARPT01 shape, cannot see this and needs its own module.
*
* Predictions, before the oracle was asked:
*   1  L 1,FIELD under USING (T+X'10'),2   base 2, disp FIELD-X'10'
*   2  L 1,FIELD under USING T+X'10',2     identical bytes to 1
*
* Same self-proving invariant as usingparen.s: one expression, two
* spellings, so the two instructions must assemble alike whatever
* the addresses turn out to be.
*
* Pre-fix (4ca0353) case 1 is 0000 0000 at rc 8 -- as370 flags its
* own IFO209 and zeroes the instruction -- where case 2 assembles
* 5810 203C. With only the base-VALUE half of the fix it is STILL
* 0000 0000 at rc 8: the base is then right and the domain is still
* filed under the private code, so using_for never offers it.
         BR    14
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
         BR    14
         DS    16F
FIELD    DS    F
         END   T
