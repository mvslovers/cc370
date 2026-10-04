* cc370#56: the operand format IFOX00 gives TPROT (X'E501') and IPTE
* (X'B221').  MVSTK5-REF JOB00321, rc 12: TPROT is SSE D1(B1),D2(B2);
* IPTE is S-format D2(B2); `IPTE R1,R2' is IFO211 and zeroed, twice.
TPI      CSECT
         USING TPI,15
         TPROT 0(1),0(2)
         TPROT 4(5),8(9)
         TPROT 12(3),16(4)
         IPTE  1,2
         IPTE  14,15
         IPTE  0(1)
         BR    14
         END
