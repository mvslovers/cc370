* SCALE AND EXPONENT MODIFIERS ON F, H, E, D AND L (CC370#761, #782).
* EACH REMARK GIVES THE CANDIDATE VALUE(S); THE ORACLE DECIDES.
DCMOD    CSECT
* SCALE ON FLOATING POINT: FRACTION SHIFTED RIGHT N HEX DIGITS
ES0      DC    ES0'1.5'                41180000
ES1      DC    ES1'1.5'                42018000
ES2      DC    ES2'1.5'                43001800
DS2      DC    DS2'1.5'                43001800 00000000
LS2      DC    LS2'1.5'                43001800 ... + LOW HALF
EL3S1    DC    EL3S1'1.5'              420180
ES6      DC    ES6'1.5'                47000001 OR 47000002 (ROUND)
ES1N     DC    ES1'-1.5'               C2018000
* EXPONENT MODIFIER ON FIXED POINT
FE1      DC    FE1'15'                 00000096
FEM1     DC    FE-1'15'                2 ROUNDED, 1 TRUNCATED
FEM2     DC    FE-1'14'                1
FEM3     DC    FE-1'-15'               -2 OR -1
FEM4     DC    FE-1'25'                3, 2 (EVEN) OR 2 (TRUNC)
HE2      DC    HE2'3'                  012C
FSE1     DC    FS4E-1'25'              28 IF E THEN S
FSE2     DC    FS1E1'3'                3C
FNE      DC    FE1'1E2'                000003E8
F3E      DC    FE2'1,2,3'              64, C8, 12C
FE9      DC    FE9'2'                  77359400
* EXPONENT MODIFIER ON FLOATING POINT
EE2      DC    EE2'1.5'                42960000
DEM2     DC    DE-2'150'               41180000 00000000
LE1      DC    LE1'1.5'                41F00000 ...
* OPEN-CODE MNOTE: IS &X SUBSTITUTED?
         LCLC  &X
&X       SETC  'ABC'
         MNOTE 1,'X=&X'
         END
