* cc370#415: a deck's addresses are MODULE-ABSOLUTE, so a section
* that is not the first one is the case every other fixture here
* misses.
*
* SECTA is the null control and sits at ESD address 0, where the
* defect cannot appear.  SECTB sits at 8, and every address the
* deck files under it is in the module's space: the TXT card's
* address, the RLD's P-position, the LD entry's address and the
* END card's entry point.  Read as section offsets they all land
* eight bytes too far -- past the declared length, leaving the
* image zero -- and the disassembly comes out as one `DS XLn' that
* REASSEMBLES TO THE SAME ZEROS.  The round trip cannot see it.
*
* Measured over the 5,528-deck corpus: 503 of 6,366 SD/PC sections
* are at a non-zero origin, in 309 modules.
*
* Keep every line under column 72.
*
SECTA    CSECT
FIRST    DC    XL3'AABBCC'
SECTB    CSECT
         ENTRY ENT
ENT      BALR  12,0
         USING *,12
         L     1,PTR
         BR    14
PTR      DC    A(TGT)
TGT      DC    XL2'CCDD'
TAIL     DC    XL4'99999999'
         END   ENT
