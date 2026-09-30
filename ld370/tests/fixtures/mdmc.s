* cc370#8: defines MC + ENTRY DUPL, refers to WW -- oracle MC
* run_iewl_autocall_oracle.py, MVSCE-LAB JOB01408
MC       CSECT
         ENTRY DUPL
         DC    V(WW)
         DC    F'0'
DUPL     DC    F'8'
         END
