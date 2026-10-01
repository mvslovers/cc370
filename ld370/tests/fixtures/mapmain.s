MAPMAIN  CSECT
         ENTRY MAPE1
         WXTRN MAPWEAK
         EXTRN MAPPCE
         BR    14
MAPE1    DC    V(MAPLIB)
         DC    A(MAPWEAK)
         DC    A(MAPPCE)
         END   MAPMAIN
