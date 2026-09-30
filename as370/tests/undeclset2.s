* cc370#97, second fixture: WHICH dictionary decides, and what a
* reference to an undeclared SET symbol does outside a model
* statement. undeclset.s settled that XF checks at definition time;
* it could not say whether that check is static (every LCLx card in
* the body, reached or not) or follows what an expansion executes,
* nor whether text order matters.
*
* Predictions, written before the capture. Every case punches its
* own letters, so the deck says which rule held:
*
*   A macro: LCLC &SKIP jumped over by AGO, then referenced
*       static dictionary   SILENT, C'AA'
*       runtime dictionary  IFO006, nothing generated
*   B macro: &LATE referenced on the card BEFORE its LCLC
*       order-sensitive     IFO006 def+exp, nothing
*       order-free          SILENT, C'BB'
*   C macro: undeclared &UC in the OPERAND of a SETC whose target
*       is declared; then DC C'C&T3.C'
*       IFO006 def+exp; T3 unassigned -> C'CC'
*       (assigned 'XX' -> C'CXXC', a third answer)
*   D macro: undeclared &UA in an AIF condition
*       IFO006 def+exp; AIF not taken -> C'D1'
*       (treated as null and taken -> C'D2')
*   E open code: the pair of A -- LCLC skipped by AGO
*       static SILENT C'EE' / runtime IFO006, nothing
*   F open code: the pair of C -> IFO006, C'FF'
*   G open code: the pair of D -> IFO006, C'G1'
*
* Column 72 is blank on every card.
         MACRO
         SKIPD
         AGO   .OVER
         LCLC  &SKIP
.OVER    ANOP
SKIPDC   DC    C'A&SKIP.A'
         MEND
         MACRO
         LATED
LATEDC   DC    C'B&LATE.B'
         LCLC  &LATE
         MEND
         MACRO
         OPNDD
         LCLC  &T3
&T3      SETC  'X&UC.X'
OPNDDC   DC    C'C&T3.C'
         MEND
         MACRO
         AIFD
         AIF   ('&UA' EQ '').EMPTY
AIFDC1   DC    C'D1'
         MEXIT
.EMPTY   ANOP
AIFDC2   DC    C'D2'
         MEND
T        CSECT
         SKIPD
         LATED
         OPNDD
         AIFD
         AGO   .OSK
         LCLC  &OSKIP
.OSK     ANOP
OSKDC    DC    C'E&OSKIP.E'
         LCLC  &OT
&OT      SETC  'Y&OU.Y'
OTDC     DC    C'F&OT.F'
         AIF   ('&OA' EQ '').OEMPTY
OADC1    DC    C'G1'
         AGO   .OEND
.OEMPTY  ANOP
OADC2    DC    C'G2'
.OEND    ANOP
         END
