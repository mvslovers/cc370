* cc370#97: Assembler XF requires a variable symbol to be declared
* with LCLx/GBLx. as370 accepts an undeclared one, assigns it and
* substitutes it, at rc 0 -- so the same source produces a DIFFERENT
* object module, not merely a missing message.
*
* Predictions, written before the oracle was asked. The controls were
* predicted too: a control nobody predicted cannot surprise you.
* MEASURED on MVSTK5-REF afterwards -- ALL EIGHT HELD.
*
*   1 &LOOSE SETC, undeclared, in a macro   IFO006 sev 8, TWICE --
*                                           definition AND expansion
*   2 DC C'/&LOOSE/'   the reference        IFO006 twice, NOTHING
*                                           generated, LOOSEDC undef
*   3 LCLC &TIGHT + SETC                    SILENT            control
*   4 DC C'/&TIGHT/'                        SILENT, 7 bytes   control
*   5 DC C'/&PARM/'    a macro parameter    SILENT, 3 bytes   control
*   6 &OSET SETC, undeclared, in OPEN CODE  IFO006 once
*   7 DC C'/&OSET/'    in open code         IFO006, nothing generated
*   8 LCLC &ODECL, declared and never set   SILENT, 2 bytes   control
*
* IFOX00: 6 statements flagged, severity 8, rc 8, section 12 bytes --
* /TIGHT/ + /P/ + //. The macro's two cards are flagged in the
* DEFINITION and the same two again in the EXPANSION, so XF checks the
* dictionary at definition time as well; the open-code pair is flagged
* once each, there being no definition to flag. No statement number is
* quoted here on purpose: editing this comment renumbers them, which is
* what invalidates a committed listing. LOOSEDC and OPENDC appear in no
* cross-reference entry -- a statement carrying an undeclared symbol
* generates NOTHING.
*
* 3/4 against 1/2 separate "undeclared" from "declared". 8 against 2
* separates it from "declared but NULL", and that pair is the fixture's
* point: &ODECL is declared and empty, substitutes to nothing and the
* statement ASSEMBLES at 2 bytes, while &LOOSE is undeclared, is not
* substituted at all and the statement generates nothing. The
* substitution path does not have that distinction today.
*
* as370 at the #97 assignment-side fix: rc 8 and severity 8 agree, and
* TWO statements are flagged where XF flags six -- the assignment in
* each scope. What is left is the DEFINITION-time check (XF flags the
* macro's cards before any call) and the reference side, which is the
* issue's second half: the deck is 22 bytes against IFOX00's 12,
* because LOOSEDC and OPENDC are still generated here.
         MACRO
&NAME    UNDECL
&LOOSE   SETC  'LOOSE'
LOOSEDC  DC    C'/&LOOSE/'
         MEND
         MACRO
&NAME    DECL  &PARM
         LCLC  &TIGHT
&TIGHT   SETC  'TIGHT'
TIGHTDC  DC    C'/&TIGHT/'
PARMDC   DC    C'/&PARM/'
         MEND
T        CSECT
         LCLC  &ODECL
         UNDECL
         DECL  P
&OSET    SETC  'O'
OPENDC   DC    C'/&OSET/'
ODECLDC  DC    C'/&ODECL/'
         END
