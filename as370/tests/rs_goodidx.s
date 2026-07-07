RSGOOD   CSECT
* The correct RS form D(B) must still assemble, and the RX form D(,B)
* (which DOES have an index field) must NOT be flagged -- proof the
* rejection is scoped to RS/SI/S and did not over-broaden to RX.
         LM    0,12,20(13)         RS D(B)   -> 980CD014 (base R13)
         L     14,12(,13)          RX D(,B)  -> 58E0D00C (base R13, index 0)
         END   RSGOOD
