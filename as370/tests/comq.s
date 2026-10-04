* COM, DXD, CXD AND Q CONSTANTS, THE CLEAN CASES (CC370#810).
MAP      DSECT
M1       DS    F
M2       DS    CL3
COMQ     CSECT
         USING COMQ,15
         L     1,QA
DA       DXD   CL5                     NO ALIGNMENT
DB       DXD   2D                      DOUBLEWORD
DH       DXD   H,F                     TWO OPERANDS
QA       DC    Q(DA)
QB       DC    Q(DB,DH)
QS       DC    Q(MAP)                  A DSECT AS A PSEUDO REGISTER
QL       DC    QL2(DB)
         CXD
QLEN     CXD
         DC    A(CF1,CG1,CF2)
         BR    14
CBLK     COM
CF1      DS    F
GBLK     COM
CG1      DS    D
CBLK     COM                           RESUMED
CF2      DS    CL6
COMQ     CSECT                         RESUMED
         DC    A(M2)
         END
