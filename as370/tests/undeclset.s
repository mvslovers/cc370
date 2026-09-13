* cc370#97: Assembler XF requires a variable symbol to be declared
* with LCLx/GBLx. as370 accepts an undeclared one, assigns it and
* substitutes it, at rc 0 -- so the same source produces a DIFFERENT
* object module, not merely a missing message.
*
* Predictions, written before the oracle was asked. The controls are
* predicted too: a control nobody predicted cannot surprise you.
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
* 3/4 against 1/2 separate "undeclared" from "declared". 8 against 2
* separates it from "declared but NULL" -- the distinction the
* substitution path does not have today, and the one the issue's
* second half turns on: a null value substitutes to nothing and the
* statement ASSEMBLES; an undeclared symbol is not substituted at all
* and the statement generates NOTHING.
*
* Predicted totals: 6 statements flagged, severity 8, rc 8, and a
* section of 12 bytes -- /TIGHT/ + /P/ + //.
* as370 today: rc 0, no message, 22 bytes -- every case substituted.
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
