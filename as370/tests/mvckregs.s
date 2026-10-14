* MVCK, MVCP and MVCS: D1(R1,B1),D2(B2),R3 -- byte 1 is R1 high
* and R3 low, neither minus one (cc370#947).  IFOX00 does not know
* these three, so the encoding is the Principles of Operation's
* and there is no reference deck.
MVCKREGS CSECT
         USING MVCKREGS,12
         MVCK  0(4,2),0(5),3          D943 2000 5000
         MVCK  16(4,10),32(11),7      D947 A010 B020
         MVCP  0(4,2),0(5),3          DA43 2000 5000
         MVCS  0(4,2),0(5),3          DB43 2000 5000
         MVCK  A(4),B,3               implicit bases: D943 C026 C02E
         MVCS  0(15,2),0(5),0         DBF0 2000 5000, the nibble edges
         BR    14
A        DS    CL8
B        DS    CL8
         END
