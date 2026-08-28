*---------------------------------------------------------------
* as370 issue #53 step 3 -- floating point: D, E and L.
*
* tests/ref/fltoracl.obj is IFOX00's own object deck for this
* module, assembled on an MVS 3.8j guest (PGM=IFOX00,
* PARM='DECK,LIST,NOLOAD,XREF(FULL),RENT') and fetched back
* byte-for-byte; tests/listref/ifox-listing-fltoracl.txt is the
* SYSPRINT from the same run.  The deck is the oracle rather than
* the listing because IFOX prints at most eight object bytes per
* statement line -- the LOW halves of the 16-byte L constants and
* the second element of a value list appear only in the deck.
*
* The mvslovers corpus contains no floating-point constant and no
* D/E/L literal at all, and the reporter's COBOL compiler cannot
* emit one (COBOL-74 has no floating-point type -- see #53), so
* this module is the only oracle there is for these encodings.
*
* What it pins:
*   D E L    default length and alignment, and the reserving DS
*            forms of each
*   value    normalisation, the excess-64 exponent, the sign, a
*            true zero and a negative zero
*   rounding IFOX ROUNDS rather than truncating: 0.1 ends ...9A
*            in both precisions, and at bit 112 for L
*   exponent E+nn / E-nn in the nominal value
*   lists    D'1.5,2.5' -- one operand, two constants
*   literals =D and =E without a decimal point (the integer route
*            they used to take) and =L, which is 16 bytes and
*            belongs in the pool's doubleword segment
*
* NOT covered, deliberately: the scale modifier (DC DS2'1.5' is
* 4300180000000000 -- recorded in #53, left out so this deck can
* be compared whole).
*---------------------------------------------------------------
FLTORCL  CSECT
         BALR  12,0
         USING *,12
*        literals -- the pool IFOX places at END
         LD    0,=D'2'
         LD    2,=D'2.0'
         LE    4,=E'1'
         LE    6,=E'1.0'
         LD    0,=D'0.1'
         LE    4,=E'0.1'
         LA    1,=L'1.5'
*        D -- long floating point, 8 bytes, doubleword
DPLAIN   DC    D'1'
DHALF    DC    D'1.5'
DNEG     DC    D'-1.5'
DZERO    DC    D'0'
DNZERO   DC    D'-0'
DTENTH   DC    D'0.1'
DBIG     DC    D'16777216'
DEXP     DC    D'1.5E2'
DNEGEXP  DC    D'1.5E-2'
DLIST    DC    D'1.5,2.5'
DLEN     DC    DL8'1.5'
*        E -- short floating point, 4 bytes, fullword
EPLAIN   DC    E'1'
EHALF    DC    E'1.5'
ENEG     DC    E'-1.5'
ETENTH   DC    E'0.1'
ETHIRD   DC    E'0.333333333'
*        L -- extended floating point, 16 bytes, doubleword
LPLAIN   DC    L'1'
LHALF    DC    L'1.5'
LNEG     DC    L'-1.5'
LTENTH   DC    L'0.1'
*        the reserving forms, for the alignment rules
DSD      DS    D
DSE      DS    E
DSL      DS    L
         END
