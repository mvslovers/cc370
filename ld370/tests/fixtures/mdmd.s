* cc370#8: defines MD + CSECT QQ (4 bytes), refers to RR
* run_iewl_autocall_oracle.py, MVSCE-LAB JOB01408
MD       CSECT
         DC    V(RR)
QQ       CSECT
         DC    F'9'
         END
