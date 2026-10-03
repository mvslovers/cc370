* cc370#258: S' and I' in conditional assembly. FS (3, 28) is the
* case measured under IFOX00 in the issue; the others follow IFNX2A
* DCSCAN and IFNX3A EVALSAT/EVALIAT: H 0/15, DS2 2/12, LL10 0/16,
* P'123.45' 2/3, PL4'1.5' 1/6, Z'-12.3' 1/2. C has neither attribute
* (IFO123 and IFO124), NODEF is undefined (IFO080 twice), all sev 4.
         MACRO
         QS    &P
         LCLA  &A,&B
&A       SETA  S'&P
&B       SETA  I'&P
         DC    AL1(&A),AL1(&B)
         MEND
AT4      CSECT
FS       DC    FS3'1.25'
HS       DC    H'1'
ES       DC    DS2'1.5'
DL       DC    LL10'1.5'
PS       DC    P'123.45'
PL       DC    PL4'1.5'
ZS       DC    Z'-12.3'
CC       DC    C'AB'
         QS    FS
         QS    HS
         QS    ES
         QS    DL
         QS    PS
         QS    PL
         QS    ZS
         QS    CC
         QS    NODEF
         END
