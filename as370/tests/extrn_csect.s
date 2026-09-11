* Oracle: MVSTK5-REF, the pinned reference, JOB00032 2026-09-11.
* It began as a capture from MVSCE-DEV and was recaptured here once
* REF was pinned. The two decks are byte-identical outside the END
* card, which differs only in the assembly date -- so the DEV deck
* was right, and we now also know that rather than assuming it.
*
* cc370#290 -- a name declared EXTRN may still name a CSECT. IFOX00
* raises IFO196 and opens private code. What this fixture settles is
* WHICH private code: one shared unnamed section, or one per name.
*
* Predictions, written down before the oracle was asked:
*   one blank ESD entry    -> the rejected sections join THE private
*                             code, the implicit one included
*   two blank entries      -> the rejected ones share a section that
*                             is not the implicit one
*   three blank entries    -> one unnamed section per rejected name
*
* Two controls inside the fixture, true under every candidate rule:
*   DC A(C) must be 00000000 with an RLD against C's ER. If it
*   resolves to a section address the name was not rejected at all.
*   A is an ordinary section, resumed once: its two pieces chain.
         DC    F'1'               implicit private code, no CSECT yet
A        CSECT
         EXTRN C
         EXTRN E
         DC    A(C)               must relocate against the ER
         DC    XL4'AAAAAAAA'
C        CSECT                    rejected: C is an ER
         DC    XL4'CCCCCCCC'
E        CSECT                    rejected: E is an ER
         DC    XL8'EEEEEEEEEEEEEEEE'
A        CSECT                    ordinary resume, the control
         DC    XL4'A2A2A2A2'
C        CSECT                    rejected again: resume, or a third?
         DC    XL4'C2C2C2C2'
         END
