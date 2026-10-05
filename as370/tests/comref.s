* COM AND DXD NAMES IN ADDRESS CONSTANTS AND LITERALS (CC370#810).
COMREF   CSECT
         USING COMREF,15
         L     1,=A(BLK)
PR1      DXD   F
         L     2,=Q(PR1)
A1       DC    A(BLK)
A2       DC    A(BLK+4)
A3       DC    A(F2-BLK)
V1       DC    V(BLK)
X1       DC    AL2(PR1)
X2       DC    A(PR1)
Q1       DC    Q(PR1)
         BR    14
BLK      COM
F1       DS    F
F2       DS    F
         END
