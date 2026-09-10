* cc370 -- AWR and AUR had each other's opcode.  AWR is the
* LONG unnormalized add (0x2E), AUR the short one (0x3E).
*
* The controls are inside the fixture: the table's own rule is
* that a floating RR opcode is its RX counterpart minus 0x40,
* and every sibling pair below is written out so a swap cannot
* return unnoticed on one line.
FPOPC    CSECT
         USING FPOPC,15
D        DS    D
         ADR   0,2
         AER   0,2
         AWR   0,2
         AUR   0,2
         SDR   0,2
         SER   0,2
         SWR   0,2
         SUR   0,2
         AD    0,D
         AE    0,D
         AW    0,D
         AU    0,D
         END
