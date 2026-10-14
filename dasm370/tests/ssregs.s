* MVCK, MVCP and MVCS: byte 1 holds two REGISTERS, R1 high and R3 low,
* and neither is a length (cc370#947).  Kept out of formats.s, whose
* offsets other checks are pinned to.
SSREGS   CSECT
         MVCK  0(4,2),0(5),3          D943 2000 5000
         MVCP  16(4,10),32(11),7      DA47 A010 B020
         MVCS  0(15,2),0(5),0         DBF0 2000 5000, the nibble edges
         BR    14
         END   SSREGS
