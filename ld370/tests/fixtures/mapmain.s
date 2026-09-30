MAPMAIN  CSECT
         ENTRY MAPE1
         WXTRN MAPWEAK
         BR    14
MAPE1    DC    V(MAPLIB)
         DC    A(MAPWEAK)
         END   MAPMAIN
