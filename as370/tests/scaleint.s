* cc370#258: S' and I' in conditional assembly.
* IFOX00 values, MVSTK5-REF JOB00320: FS 3/28, H 0/15, DS2 2/12,
* LL10 0/16, P'123.45' 2/3, PL4'1.5' 1/6, Z'-12.3' 1/2. C has neither
* attribute: IFO123 for S', IFO123 and IFO124 for I'. NODEF is
* undefined: IFO080 for each. All severity 4.
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
