* COM, DXD, CXD AND Q-TYPE CONSTANTS (CC370#810).
COMDXD   CSECT
         USING COMDXD,15
         L     1,QDX                   LOAD THE PR OFFSET
QDX      DC    Q(DX)                   OFFSET OF DX IN THE PRV
QLEN     CXD                           LENGTH OF THE PRV
         BR    14
DX       DXD   2F                      AN EXTERNAL DUMMY SECTION
CBLK     COM                           A COMMON SECTION
CF1      DS    F
CF2      DS    CL8
         END
