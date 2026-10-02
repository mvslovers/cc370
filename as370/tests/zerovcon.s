* A V-con with duplication factor zero generates nothing and gets no ER
* (cc370#199). Measured on HMASMTMD (MVSBLD): IFOX00 has no ESD entry
* for its three DC 0V(...) names. ONE is the control: an ER.
ZEROV    CSECT
         DC    0V(ZERO)
         DC    V(ONE)
         END
