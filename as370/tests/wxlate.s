* WXTRN BEFORE AND AFTER THE V-CONS THAT NAME IT (CC370 WEAK REFS).
         WXTRN FIRST
WXL      CSECT
         USING WXL,15
         L     15,=V(LATE)
         L     14,=V(FIRST)
         BR    14
VLATE    DC    V(LATE)
VFIRST   DC    V(FIRST)
         WXTRN LATE
         END
