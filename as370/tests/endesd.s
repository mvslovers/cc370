* The END card's ESDID comes from the FIRST sub-operand.
* The entry point sits in the SECOND control section on
* purpose: a fix that writes a constant 0001 instead of
* resolving the symbol passes on a one-section module and
* fails here.  Correct answer: ESDID 0002, address 000008.
SECTA    CSECT
         BR    14
SECTB    CSECT
ENTB     BR    14
         END   ENTB,(C'PLS1911',0701,78177)
