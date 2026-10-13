MAINX    CSECT
         USING *,15
         L     1,=A(COUNT)
         L     2,=A(NAMEX)
         L     3,=V(SUBX)
         BR    14
         LTORG
COUNT    COM
         DS    F
NAMEX    CSECT
         DC    CL8'FROMA'
         END
