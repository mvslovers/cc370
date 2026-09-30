* controls for #528: literals whose value carries an operator,
* a modifier or a sign. None is combined with another term, so
* none may draw IFO161 -- the operator is inside the literal.
CTL      CSECT
         USING CTL,15
         MVC   0(3,1),=C'A+B'
         MVC   0(3,1),=C'''+'''
         L     2,=A(CTL+4)
         L     3,=F'-1'
         L     4,=FL4'+2'
         L     5,=FS3'1'
         MVC   0(4,1),=4C'-'
         L     6,=(2*2)F'7'
         MVC   0(2,1),=XL2'FF'
         L     7,=V(EXT)
         LTORG
         END
