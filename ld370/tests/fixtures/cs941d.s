SUBZ     CSECT
         USING *,15
         L     1,=A(COUNT)
         BR    14
         LTORG
COUNT    COM
         DS    2F
         END
