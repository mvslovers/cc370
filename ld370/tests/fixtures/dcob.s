* cc370#522: OB, then QQ with ENTRY QE at x10, then OC -- oracle OB
* run_iewl_dupcsect_oracle.py, MVSCE-LAB JOB01409
OB       CSECT
         DC    A(QQ)
         DC    A(OC)
QQ       CSECT
         ENTRY QE
         DC    A(OB)
         DC    A(QQ)
QE       DC    CL8'QQ2'
         DC    4F'0'
OC       CSECT
         DC    CL4'OC'
         DC    A(QE)
         END
