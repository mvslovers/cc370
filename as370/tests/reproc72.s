* REPRO and a punched card with a non-blank column 72 (cc370#140).
* IBCDASDI/IBCDMPRS draw IFO053 on the REPRO after such a card. A:
* col 72 X then REPRO; B: col 72 X then a DC; C: blank col 72.
REPROC72 CSECT
         DC    C'1'
         REPRO
PUNCHED-A WITH A NON-BLANK COLUMN 72                                   X
         REPRO
PUNCHED-A2 BLANK COLUMN 72
         DC    C'2'
         REPRO
PUNCHED-B WITH A NON-BLANK COLUMN 72                                   X
         DC    C'3'
         REPRO
PUNCHED-C BLANK COLUMN 72
         DC    C'4'
         END
