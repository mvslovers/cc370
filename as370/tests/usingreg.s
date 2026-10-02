* IFO195 INVALID USING OR DROP STATEMENT (severity 12). IFOX00
* raises it on two paths in IFNX5A, and as370 had neither:
*
*   USING  a base register that is not absolute, is undefined, is
*          above 15, or is 0 anywhere but as the only register
*          (USI700). Registers named BEFORE the bad one are entered,
*          the bad one and every later one are not.
*   DROP   a register that holds no domain (DRP500) -- and the
*          statement stops there, later registers stay live -- or
*          an invalid register (DRP700), after which it goes on.
*
* Predictions, from the IFOX source, written before the capture:
*   1  IFO188 + IFO195         2  IFO195        3  IFO195
*   4  IFO195, 5 is entered    5  silent (control)
*   6  IFO195, 6 entered, 7 not: the L after it is IFO209
*   7  IFO195
*   8  IFO195, 6 NOT dropped: the L after it uses base 6
*   9  IFO188 + IFO195, 6 IS dropped: the L after it uses base 5
*  10  IFO195                 11  silent (control)
* Ten statements flagged, highest severity 12.
T        CSECT
         BALR  12,0
         USING *,12
FLD      DS    F
         USING FLD,UNDEFR       1: undefined register symbol
         USING FLD,16           2: register out of range
         USING FLD,FLD          3: relocatable register
         USING FLD,5,0          4: register 0 not first
         USING FLD,0            5: register 0 alone -- control
         DROP  0                   control
         USING FLD,6,17,7       6: bad middle register
         L     1,FLD+8192          base 7 if entered
         DROP  9                7: register never in use
         DROP  9,6              8: unused first, then 6
         L     1,FLD               base 6 if 6 still live
         DROP  UNDEFR,6         9: undefined first, then 6
         L     1,FLD               base 5 if 6 was dropped
         DROP  16              10: out of range
         DROP  12              11: control
         END
