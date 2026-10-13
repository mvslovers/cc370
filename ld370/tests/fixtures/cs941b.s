SUBX     CSECT
         USING *,15
         L     1,=A(COUNT)
         L     2,=A(NAMEX)
         BR    14
         LTORG
COUNT    CSECT
         DC    F'100'
NAMEX    CSECT
         DC    CL8'FROMB'
         END
