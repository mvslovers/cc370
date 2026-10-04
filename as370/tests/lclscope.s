* A LOCAL SET SYMBOL SHADOWS A GLOBAL OF THE SAME NAME, AND ONLY IN
* THE CONTEXT THAT DECLARES IT LOCAL.  EVERY DC BELOW NAMES THE VALUE
* IT SHOULD HOLD IN ITS REMARK.
         MACRO
         MA
         LCLA  &A
         DC    Y(&A)                   0 - LOCAL, FRESH
&A       SETA  7
         DC    Y(&A)                   7
         MEND
         MACRO
         MB
         GBLA  &B
&B       SETA  9
         DC    Y(&B)                   9
         MEND
         MACRO
         MB2
         GBLA  &B
         DC    Y(&B)                   9 - THE GLOBAL MB SET
         MEND
         MACRO
         MCX
         LCLA  &C(3)
&C(2)    SETA  8
         DC    Y(&C(2))                8
         MEND
         MACRO
         MD1
         GBLA  &D
&D       SETA  6
         MEND
         MACRO
         MD2
         LCLA  &D
&D       SETA  1
         DC    Y(&D)                   1
         MEND
         MACRO
         MD3
         GBLA  &D
         DC    Y(&D)                   6
         MEND
         MACRO
         MEX
         LCLC  &E
&E       SETC  'ZZ'
         DC    C'&E'                   ZZ
         MEND
LCLSCOPE CSECT
         GBLA  &A
&A       SETA  3
         MA
         DC    Y(&A)                   3 - THE GLOBAL SURVIVES
         LCLA  &B
&B       SETA  4
         MB
         DC    Y(&B)                   4 - OPEN-CODE LOCAL
         MB2
         GBLA  &C(3)
&C(2)    SETA  5
         MCX
         DC    Y(&C(2))                5
         MD1
         MD2
         MD3
         GBLC  &E
&E       SETC  'XY'
         MEX
         DC    C'&E'                   XY
         END
