* a scale modifier on a LITERAL. FS3'65535' is 65535 x 2**3 =         
* 524280 = X'0007FFF8'. The DC form below is the control: it sits     
* in the same assembly and as370 already gets it right, so this       
* cannot be the pool, the alignment or the ordering.                  
T        CSECT                                                        
         USING T,15                                                   
         CL    11,=FS3'65535'                                         
         CL    11,=F'524280'                                          
         LH    2,=HS2'100'                                            
A        DC    FS3'65535'               the control, as a DC          
B        DC    F'524280'                same value, no scale          
C        DC    HS2'100'                                               
         LTORG                                                        
         END                                                          
