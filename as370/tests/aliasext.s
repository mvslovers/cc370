* cc370#186 -- an EQU alias of an EXTERNAL relocates against
* the ER entry, not the enclosing section.  JEXTRN generates
* exactly this shape: EXTRN IFNX6C01 / ERRMSGS EQU IFNX6C01.
*
* The control is INSIDE the fixture: EQU makes EXTA and
* ALIASA one symbol, so both DC cards and both literals must
* carry the same relocation ESDID.  A wrong answer shows
* without the oracle.
ALIASX   CSECT
         EXTRN EXTA
ALIASA   EQU   EXTA
         USING ALIASX,15
         L     1,=A(EXTA)
         L     2,=A(ALIASA)
         DC    A(EXTA)
         DC    A(ALIASA)
         LTORG
         END
