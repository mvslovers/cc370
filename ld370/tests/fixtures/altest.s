* The module of the #466 alias oracle (MVSCE-LAB JOB01367): entry
* START at X'10', and ALT2 an ENTRY at X'14' -- so an alias that
* names a symbol of the module is told apart from one that does not.
ALTEST   CSECT
         ENTRY ALT2
         DC    XL16'00'
START    SR    15,15
         BR    14
ALT2     LA    15,4
         BR    14
         END   START
