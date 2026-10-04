* IFO203 BOUNDARIES (CC370#776).  ONE CONSTANT PER STATEMENT UNLESS
* NOTED, SO A WARNING NAMES ITS STATEMENT.  CANDIDATE RULES FOR F:
*  (A) SIGNED RANGE      -2**31 .. 2**31-1
*  (B) MAGNITUDE         ABS(V) .LT. 2**31  (FLAGS -2**31)
*  (C) UNSIGNED ALLOWED  -2**31 .. 2**32-1
* F'2147483648' SPLITS A FROM C, F'-2147483648' SPLITS B FROM A.
IFO203   CSECT
F1       DC    F'2147483647'
F2       DC    F'2147483648'
F3       DC    F'4294967295'
F4       DC    F'4294967296'
F5       DC    F'-2147483648'
F6       DC    F'-2147483649'
F7       DC    F'-4294967295'
F8       DC    F'99999999999'
H1       DC    H'32767'
H2       DC    H'32768'
H3       DC    H'65535'
H4       DC    H'65536'
H5       DC    H'-32768'
H6       DC    H'-32769'
L31      DC    FL3'8388607'
L32      DC    FL3'8388608'
L33      DC    FL3'16777215'
L34      DC    FL3'16777216'
L35      DC    FL3'-8388608'
L36      DC    FL3'-8388609'
L11      DC    FL1'127'
L12      DC    FL1'128'
L13      DC    FL1'255'
L14      DC    FL1'256'
L15      DC    HL1'-129'
Y1       DC    Y(32767)
Y2       DC    Y(32768)
Y3       DC    Y(65535)
Y4       DC    Y(65536)
Y5       DC    Y(-32768)
Y6       DC    Y(-32769)
A1       DC    AL1(255)
A2       DC    AL1(256)
A3       DC    AL2(65536)
A4       DC    AL3(-1)
E1       DC    FE9'2'
E2       DC    FE9'3'
M1       DC    F'1,2147483648,4294967296'
M2       DC    2F'2147483648'
M3       DC    H'1,65536'
D1       DC    E'1E75'
D2       DC    E'1E76'
D3       DC    D'1E76'
D4       DC    L'1E76'
D5       DC    E'1E-80'
         END
