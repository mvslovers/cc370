* Undefined symbols in the four shapes nsf370's modules hit them
* (mvslovers/nsf370): a branch target, a displacement symbol, a
* difference of two, and a literal adcon.  IFOX00 flags each one
* IFO188 (severity 8, jermsgcd.asm SEV188) and zeroes the whole
* instruction -- but assembles the literal's reference normally.
UNDEFSYM CSECT
         USING UNDEFSYM,15
         BE    NOWHERE            undefined branch target
         LH    3,NOSUCH(,7)       undefined displacement symbol
         MVC   FIELD-BASE(8,2),0(3)  undefined difference
         L     4,=A(NOVAL)        undefined inside a literal adcon
DEFHERE  DC    A(DEFHERE)         control: a defined symbol resolves
         END
